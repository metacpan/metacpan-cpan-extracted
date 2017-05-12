#
# Mail/Salsa/Action/Unsubscribe.pm
# Last Modification: Fri Sep 23 15:24:08 WEST 2005
#
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Unsubscribe;

use 5.008000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Mail::Salsa::Logs qw(logs);
use Mail::Salsa::Utils qw(file_path);
use Fcntl qw(:flock);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mail::Salsa ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(&remove_from_list);

our $VERSION = '0.04';

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
	if($self->{'config'}->{'unsubscribe'} eq "n") {
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "UNSUBSCRIBE",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from => "$name-owner\@$domain",
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
	if(scalar(@{$exist}) < scalar(@emails)) {
		my @notexist = ();
		my %seen = ();
		@seen{@{$exist}} = (0 .. $#{$exist});
		for my $e (@emails) { exists($seen{$e}) or push(@notexist, $e); }
		Mail::Salsa::Utils::tplsendmail(
			smtp_server => $self->{'smtp_server'},
			timeout     => $self->{'timeout'},
			label       => "EMAILNOTEXIST",
			lang        => $self->{'config'}->{'language'},
			vars        => {
				from   => "$name\-owner\@$domain",
				to     => $self->{'from'},
				list   => $self->{'list'},
				emails => join("\n", @notexist),
			}
		);
		(scalar(@notexist) < scalar(@emails)) or return();
	}
	my $kfile = file_path($self->{'list'}, $self->{'list_dir'}, 'stamp.txt');
	if(my $stamp = Mail::Salsa::Utils::get_key($kfile)) {
		if(my $human = Mail::Salsa::Utils::lookup4key($self->{'message'}, $stamp)) {
			if(&remove_from_list($file, { $self->{'from'} => 0 })) {
				Mail::Salsa::Utils::tplsendmail(
					smtp_server => $self->{'smtp_server'},
					timeout     => $self->{'timeout'},
					label       => "EMAIL_REMOVED",
					lang        => $self->{'config'}->{'language'},
					vars        => {
						from => "$name\-owner\@$domain",
						to   => $self->{'from'},
						list => $self->{'list'},
					}
				);
			}
		} else {
			for my $email (@{$exist}) {
				Mail::Salsa::Utils::tplsendmail(
					smtp_server => $self->{'smtp_server'},
					timeout     => $self->{'timeout'},
					label       => "CONFIRM_UNSUB",
					lang        => $self->{'config'}->{'language'},
					vars        => {
						from   => "$name\-unsubscribe\@$domain",
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

sub remove_from_list {
	my $file = shift;
	my $addrs = shift;

	my $pattern = '[^\@<>(),;:\s]+\@([\w\-]+\.)+[a-zA-Z]{2,4}';
	my $n = (my $exist) = scalar(keys(%{$addrs}));
	open(LIST, "<", $file) or die("$!");
	flock(LIST, LOCK_EX);
	open(TMPLIST, ">", "$file\.tmp") or die("$!");
	select(TMPLIST);
	while(<LIST>) {
		if($exist &&
			/^[^\#]/ &&
				/<?($pattern)>?/ &&
					exists($addrs->{$1})) {
			$addrs->{$1} = 1;
			$exist--;			
			next;
		}
		print TMPLIST $_;
	}
	close(TMPLIST);
	flock(LIST, LOCK_UN);
	close(LIST);
	if($exist < $n) { rename("$file\.tmp", $file); }
	else { unlink("$file\.tmp"); }
	return($n - $exist);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Unsunscribe - Extension to unsubscribe the members
from the mailing list.

=head1 SYNOPSIS

  use Mail::Salsa::Action::Unsubscribe;

=head1 DESCRIPTION

Stub documentation for Mail::Salsa::Action::Unsubscribe, created by
h2xs. It looks like the author of the extension was negligent enough to
leave the stub unedited.

Blah blah blah.

  To unsubscribe my self from a mailing list send a email to:

  To: list-unsubscribe@example.org

  To unsubscribe other people from a mailing list send a email to:

  To: list-unsubscribe@example.org
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

Copyright (C) 2005 by Henrique M. Ribeiro Dias

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
