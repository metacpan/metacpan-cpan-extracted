#
# Mail/Salsa/Action/Return.pm
# Last Modification: Wed Apr 20 17:09:05 WEST 2005
#
# Copyright (c) 2005 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Mail::Salsa::Action::Return;

use 5.008000;
use strict;
use warnings;

require Exporter;
use Mail::Salsa::Logs qw(logs);
use Mail::Salsa::Action::Unsubscribe qw(remove_from_list);
use Mail::Salsa::Utils qw(file_path);
use SelfLoader;

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

SelfLoader->load_stubs();

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
	my $returnedfile = join("/", $self->{'tmp_dir'}, 'file');
	(-e $returnedfile) or return();
	my $addrs = &find_wrong_email($returnedfile);
	scalar(keys(%{$addrs})) or return();
	my $file = file_path($self->{'list'}, $self->{'list_dir'}, "list\.txt");
	my $res = remove_from_list($file, $addrs);
	for my $email (keys(%{$addrs})) {
		$self->logs(join("", "[user unknown unsubscribed] user: ", $email), "list") if($email);
	}
#exit();
	return();
}

sub find_wrong_email {
	my $file = shift;

	my %addresses = ();
	open(FILE, "<", $file) or return({});
	while(<FILE>) {
		if(my $email = &look4email($_)) { exists($addresses{$email}) or $addresses{$email} = 0; }
	}
	close(FILE);
	return(\%addresses);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__DATA__

sub look4email {
	local $_ = shift;

	/^550 5\.1\.1 \<?([^\>\@ ]+\@[^\> ]+)\>?\.\.\. User unknown\s+/ and return($1);
	/450 \<?([^\>\@ ]+\@[^\> ]+)\>?\: Recipient address rejected\: User unknown/ and return($1);

	return(0);
}

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mail::Salsa::Action::Return - Extension to handles the returned
messages.

=head1 SYNOPSIS

  use Mail::Salsa::Action::Return;

=head1 DESCRIPTION

Stub documentation for Mail::Salsa, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

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
