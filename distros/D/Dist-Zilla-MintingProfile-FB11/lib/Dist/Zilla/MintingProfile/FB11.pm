package Dist::Zilla::MintingProfile::FB11;

# ABSTRACT: Mints a new FB11 site
our $VERSION = '0.017';
use Moose;
use 5.014;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::FB11 - Mints a new FB11 site

=head1 VERSION

version 0.017

=head1 NAME

Dist::Zilla::MintingProfile::FB11 - Mints a new FB11 site

=head1 PROFILES

=head2 default

Mints a new FB11 top-level application.

This is the default if you don't provide C<-p>.

    dzil new -P FB11 MyApp

=head2 FB11X

Mints a new FB11X component.

    dzil new -P FB11 -p FB11X MyApp::FB11X::ComponentName

=head2 Form

Mints a new form (use with C<dzil add>)

    cd MyApp-FB11X-ComponentName
    dzil add -P FB11 -p Form MyApp::FB11X::ComponentName::Form::EntityName

=head2 Controller

Mints a new controller (use with C<dzil add>)

    cd MyApp-FB11X-ComponentName
    dzil add -P FB11 -p Form MyApp::FB11X::ComponentName::Controller::EntityName

The templates will need to be created in the directory:

    lib/auto/MyApp/FB11X/ComponentName/root/templates/entityname/*.tt

=head1 AUTHOR

Alastair McGowan-Douglas <altreus@altre.us>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alastair McGowan-Douglas.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
