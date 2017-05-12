package Dist::Zilla::Plugin::Web::RelaxedVersion;
$Dist::Zilla::Plugin::Web::RelaxedVersion::VERSION = '0.0.10';
# ABSTRACT: Allow free-form version of the distribution, currently using dirty hack

use Moose;

with 'Dist::Zilla::Role::Plugin';

use version 0.82;

has 'enabled' => (
    isa     => 'Bool',
    is      => 'rw',
    
    default => 0
);


#================================================================================================================================================================================================================================================
sub BUILD {
    my ($self)      = @_;
    
    if ($self->enabled) {
        no warnings;
        
        *version::is_lax = sub { 1 };
    }
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Web::RelaxedVersion - Allow free-form version of the distribution, currently using dirty hack

=head1 VERSION

version 0.0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [Web::RelaxedVersion]
    enabled = 0 ; default

=head1 DESCRIPTION

This plugins uses a dirty hack to allow you to have a free-form version for your distribution, like : '1.0.8-alpha-2-beta-3'.
Because the hack is really dirty (a global override for version::is_lax), one need to explicitly enable this plugin with "enabled = 1" config option. 

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
