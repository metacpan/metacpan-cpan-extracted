package ExtUtils::ModuleMaker::Licenses::Local;
use strict;
use warnings;

BEGIN {
    use base qw(Exporter);
    use vars qw( @EXPORT_OK $VERSION );
    $VERSION = 0.56;
    @EXPORT_OK   = qw(Get_Local_License Verify_Local_License);
}

my %licenses = (
    looselips => { 
	function => \&License_LooseLips,
        fullname => 'Loose Lips License (1.0)',
    },
);

sub Get_Local_License {
    my $choice = shift;

    $choice = lc ($choice);
    return ($licenses{$choice}{function}) if (exists $licenses{$choice});
    return;
}

sub Verify_Local_License {
    my $choice = shift;
    return (exists $licenses{lc ($choice)});
}

sub interact {
    my $class = shift;
    return (bless (
        { map { ($licenses{$_}{fullname})
                     ? ($_ => $licenses{$_}{fullname})
                     : ()
              } keys (%licenses)
        }, ref ($class) || $class)
    );
}

sub License_LooseLips {
    my %license;

    $license{COPYRIGHT} = <<EOFCOPYRIGHT;
This program is licensed under the...

	Loose Lips License

The full text of the license can be found in the
LICENSE file included with this module.
EOFCOPYRIGHT

$license{LICENSETEXT} = <<EOFLICENSETEXT;
Loose Lips License
Version 1.0

Copyright (c) ###year### ###organization###. All rights reserved.

This software is the intellectual property of ###organization###.  Its
contents are a trade secret and are not to be shared with anyone outside
the organization.

Remember, "Loose lips sink ships."
EOFLICENSETEXT

    return (\%license);
}

1;

#################### DOCUMENTATION ####################

=head1 NAME

ExtUtils::ModuleMaker::Licenses::Local - Templates for the module's License/Copyright

=head1 SYNOPSIS

  use ExtUtils::ModuleMaker::Licenses::Local;
  blah blah blah

=head1 DESCRIPTION

This package holds subroutines imported and used by
ExtUtils::ModuleMaker to include license and copyright information in a
standard Perl module distribution.

=head1 USAGE

This package always exports two functions:

=over 4

=item * C<Get_Local_License>

=item * C<Verify_Local_License>

=back

=head2 License_LooseLips

Purpose   : Get the copyright pod text and LICENSE file text for this license

=head1 BUGS

None known at this time.

=head1 AUTHOR/MAINTAINER

ExtUtils::ModuleMaker was originally written in 2001-02 by R. Geoffrey Avery
(modulemaker [at] PlatypiVentures [dot] com).  Since version 0.33 (July
2005) it has been maintained by James E. Keenan (jkeenan [at] cpan [dot]
org).

=head1 SUPPORT

Send email to jkeenan [at] cpan [dot] org.  Please include 'modulemaker'
in the subject line.

=head1 COPYRIGHT

Copyright (c) 2001-2002 R. Geoffrey Avery.
Revisions from v0.33 forward (c) 2005, 2017 James E. Keenan.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

F<ExtUtils::ModuleMaker>, F<modulemaker>, perl(1).

=cut

