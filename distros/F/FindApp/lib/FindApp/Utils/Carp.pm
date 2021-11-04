package FindApp::Utils::Carp;

use Carp qw(carp croak cluck confess);
use Exporter qw(import);

our @EXPORT_OK = qw(carp croak cluck confess @CARP_NOT);
our @EXPORT = @EXPORT_OK;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our @CARP_NOT = qw{ 

    FindApp
    FindApp::Behavior::Exporter
    FindApp::Git
    FindApp::Object
    FindApp::Object::Behavior
    FindApp::Object::Behavior::Devperl
    FindApp::Object::Behavior::Loader
    FindApp::Object::Class
    FindApp::Object::State
    FindApp::Object::State::Group
    FindApp::Object::State::Group::Behavior
    FindApp::Object::State::Group::Behavior::Overloading
    FindApp::Object::State::Group::Class
    FindApp::Object::State::Group::State
    FindApp::Object::State::Group::State::Dirs
    FindApp::Subs
    FindApp::Utils
    FindApp::Utils::Assert
    FindApp::Utils::Carp
    FindApp::Utils::Debug
    FindApp::Utils::Foreign
    FindApp::Utils::List
    FindApp::Utils::Misc
    FindApp::Utils::Objects
    FindApp::Utils::Package
    FindApp::Utils::Package::Object
    FindApp::Utils::Paths
    FindApp::Utils::Syntax
    FindApp::Vars
    applib
    gitlib

};

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Carp - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Carp;

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

