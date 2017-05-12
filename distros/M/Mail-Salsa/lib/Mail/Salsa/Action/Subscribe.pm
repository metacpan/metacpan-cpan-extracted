#
# Mail/Salsa/Action/Subscribe.pm
# Last Modification: Thu Jul  1 12:02:05 WEST 2004
#
# Copyright (c) 2004 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Subscribe;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Mail::Salsa::Logs qw(logs);
use Mail::Salsa::Utils qw(file_path);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {@_};
	bless ($self, $class);
	$self->process_msg();
	return($self);
}

sub process_msg {
	my $self = shift;

	my ($name, $domain) = split(/\@/, $self->{'list'});
	if($self->{'config'}->{'subscribe'} eq "n") {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "SUBSCRIBE",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from => "$name\-owner\@$domain",
				to   => $self->{'from'},
				list => $self->{'list'},
			}
		);
		return();
	}
	my $file = file_path($self->{'list'}, $self->{'list_dir'}, "list\.txt");
	my @emails = ();
	if(exists($self->{'headers'}->{'0.0'}->{'cc'})) {
		@emails = split(/ *[\,\;] */, $self->{'headers'}->{'0.0'}->{'cc'});
		Mail::Salsa::Utils::only_addresses(\@emails);
	} else { $emails[0] = $self->{'from'}; }
	my $exist = Mail::Salsa::Utils::check4email(\@emails, $file);
	if(my $n = scalar(@{$exist})) {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "EMAIL_EXISTS",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from   => "$name\-owner\@$domain",
				to     => $self->{'from'},
				list   => $self->{'list'},
				emails => join("\n", @{$exist}),
			}
		);
		($n < scalar(@emails)) or return();
	}
	my $kfile = file_path($self->{'list'}, $self->{'list_dir'}, 'stamp.txt');
	if(my $stamp = Mail::Salsa::Utils::get_key($kfile)) {
		if(my $human = Mail::Salsa::Utils::lookup4key($self->{'message'}, $stamp)) {
			$self->add2list();
			Mail::Salsa::Utils::tplsendmail(
				smtp_server => $self->{'smtp_server'},
				timeout     => $self->{'timeout'},
				label       => "EMAIL_ADDED",
				lang        => $self->{'config'}->{'language'},
				vars        => {
					from => "$name\-owner\@$domain",
					to   => $self->{'from'},
					list => $self->{'list'},
				}
			);
		} else {
			for my $email (@emails) {
				Mail::Salsa::Utils::tplsendmail(
					smtp_server => $self->{'smtp_server'},
					timeout     => $self->{'timeout'},
					label       => "CONFIRM_SUB",
					lang        => $self->{'config'}->{'language'},
					vars        => {
						from   => "$name\-subscribe\@$domain",
						to     => $email,
						list   => $self->{'list'},
						stamp  => $stamp,
						origin => $self->{'from'},
					}
				);
			}
		}
	}
	return();
}

sub add2list {
	my $self = shift;

	my $file = file_path($self->{'list'}, $self->{'list_dir'}, "list\.txt");
	open(LIST, ">>", $file) or die("$!");
	print LIST $self->{'from'}, "\n";
	close(LIST);
	return();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Subscribe - Extension to subscribe the members to
the mailing list.

=head1 SYNOPSIS

  use Mail::Salsa::Action::Subscribe;

=head1 DESCRIPTION

Stub documentation for Mail::Salsa, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

To subscribe my self to a mailing list:

To: list-subscribe@example.org

To subscribe other people to a mailing list:

To: list-subscribe@example.org
Cc: mywife@example.org, myfather@example.org

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Henrique M. Ribeiro Dias, E<lt>hdias@aesbuc.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
