package FindApp::Utils::Foreign;

use v5.10;
use strict;
use warnings;

use File::Spec   qw();

#################################################################

use Exporter     qw(import);
our $VERSION = v1.0;

my %Exported_Imports; BEGIN {

   %Exported_Imports = (
    "Carp"           => [ qw(carp croak cluck confess) ],
    "Cwd"            => [ qw(abs_path getcwd) ],
    "Data::Dump"     => [ qw(dd pp) ],
    "File::Basename" => [ qw(basename dirname fileparse) ],
    "Scalar::Util"   => [ qw(blessed looks_like_number refaddr reftype set_prototype) ],
   );

   while (my($module, $imports) = each %Exported_Imports) {
       eval qq{ require $module; 1 } || die;
       $module->import(@$imports);
   }

}

{
    no warnings qw(redefine prototype);

    sub  abs_path(_)           {  &Cwd::abs_path                    }
    sub  basename(_;$)         {  &File::Basename::basename         }
    sub  blessed(_)            {  &Scalar::Util::blessed            }
    sub  dirname(_)            {  &File::Basename::dirname          }
    sub  getcwd()              {  &Cwd::getcwd                      }
    sub  looks_like_number(_)  {  &Scalar::Util::looks_like_number  }
    sub  refaddr(_)            {  &Scalar::Util::refaddr            }
    sub  reftype(_)            {  &Scalar::Util::reftype            }
}

our @EXPORT_OK = sort abs2rel => map { @$_ } values %Exported_Imports;

our %EXPORT_TAGS  =  %Exported_Imports;
$EXPORT_TAGS{all} = \@EXPORT_OK;

sub abs2rel(_) {
    my($path) = @_;
    return File::Spec->abs2rel($path);
}

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Foreign - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Foreign;

=head1 DESCRIPTION

=head2 Exports

=over

=item abs2rel

=back

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

