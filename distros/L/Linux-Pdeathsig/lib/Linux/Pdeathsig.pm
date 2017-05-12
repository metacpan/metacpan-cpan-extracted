package Linux::Pdeathsig;

use 5.008007;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Linux::Pdeathsig ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	set_pdeathsig
    get_pdeathsig
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	set_pdeathsig
    get_pdeathsig
);

our $VERSION = '0.10';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;  # see L<perlmodstyle>

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Linux::Pdeathsig::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Linux::Pdeathsig', $XS_VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Linux::Pdeathsig - Perl interface to request a signal on parent death 

=head1 SYNOPSIS

  use Linux::Pdeathsig;

  set_pdeathsig(9);
  # now you will get SIGKILL when the parent process ends

  my $v = &get_pdeathsig;
  # get the signal that will be sent when the parent process ends

=head1 DESCRIPTION

This simple module provides two functions to set or get the signal that
the linux kernel will send when the parent process dies.  get_pdeathsig
returns 0 when no signal has been set.  set_pdeathsig(0) will clear the
setting.  Both functions croak on error.

=head1 EXPORTS

set_pdeathsig, get_pdeathsig by default.

=head1 SEE ALSO

prctl(2) Linux man page.

=head1 AUTHOR

Eric Clark, E<lt>zerohp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Eric Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
