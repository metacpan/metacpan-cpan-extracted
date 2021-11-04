package FindApp::Utils::Paths;

use v5.10;
use strict;
use warnings;

use FindApp::Utils::Carp;

use FindApp::Utils::Foreign qw(
    abs2rel
    abs_path
    fileparse
    dirname
    basename
);
use FindApp::Utils::Package qw(
    PACKAGE
);

#################################################################

sub basename_noext  ( _ ) ;
sub dir_file_ext    ( _ ) ;
sub file_dir_ext    ( _ ) ;
sub is_absolute     ( _ ) ;
sub is_relative     ( _ ) ;
sub module2path     ( _ ) ;
sub pathify_modules ( @ ) ;

#################################################################

use Exporter qw(import);
our $VERSION   = v1.0;
our @EXPORT_OK = qw(
    basename_noext
    dir_file_ext
    file_dir_ext
    is_absolute 
    is_relative
    module2path 
    pathify_modules
);
# Re-exports
push @EXPORT_OK, qw(
    abs2rel
    abs_path
    basename
    dirname
    fileparse
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

#################################################################

sub hate_empty {
    for (@_) { 
        croak "paths cannot be undef" unless defined;
        croak "paths cannot be empty" unless length;
    }
}

sub file_dir_ext(_)     { &hate_empty; fileparse shift, qr/\..*/  }
sub dir_file_ext(_)     { &hate_empty; (&file_dir_ext)[1,0,2]     }
sub basename_noext(_)   { &hate_empty; scalar file_dir_ext shift  }
sub is_absolute(_)      { &hate_empty; substr(shift, 0, 1) eq "/" }
sub is_relative(_)      { &hate_empty; !&is_absolute              }
sub module2path(_)      { &hate_empty; PACKAGE(shift)->pmpath     }

# only works on ones with at least one double-colon
sub pathify_modules(@)  { &hate_empty; map { /^\w+(::\w+)+$/ ? module2path : $_  } @_ }

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Paths - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Paths;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item basename_noext

=item dir_file_ext

=item file_dir_ext

=item is_absolute

=item is_relative

=item module2path

=item pathify_modules

=back

=head2 Private Functions

=over

=item hate_empty

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

