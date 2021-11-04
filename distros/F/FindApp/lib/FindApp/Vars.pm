package FindApp::Vars;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);

BEGIN {
    # Can cause warnings in buggy core Env.pm module otherwise:
    $ENV{MANPATH} //= q(); 
}

our $VERSION = v1.0;

my @Internals; BEGIN {
   @Internals = qw(
       $Root
       $Bin @Bin
       $Lib @Lib
       $Man @Man
       $Debugging
       $Tracing
   );
}

my @Externals; BEGIN {
   @Externals = qw(
       $FINDAPP_DEBUG
       $FINDAPP_DEBUG_SHORTEN
       $FINDAPP_TRACE

       @PATH
       $MANPATH 
       @MANPATH

       $GIT_DIR
       $APP_ROOT
   );
}

use vars @Internals;
use Env  @Externals;

our @EXPORT      = (@Internals, @Externals);
our @EXPORT_OK   = @EXPORT; 
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    app => \@Internals,
    env => \@Externals,
);

$Debugging = $FINDAPP_DEBUG if defined $FINDAPP_DEBUG && !defined $Debugging;
$Tracing   = $FINDAPP_TRACE if defined $FINDAPP_TRACE && !defined $Tracing;

1;

=encoding utf8

=head1 NAME

FindApp::Vars - FIXME

=head1 SYNOPSIS

 use FindApp::Vars;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item FIXME

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

