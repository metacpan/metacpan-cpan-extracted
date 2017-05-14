use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::SVK;
# ABSTRACT: all SVK plugins in one go

use Moose;
use Class::MOP;

with 'Dist::Zilla::Role::PluginBundle';

# bundle all svk plugins
my @names   = qw{ Check Commit Tag Push };

my %multi;
for my $name (@names) {
    my $class = "Dist::Zilla::Plugin::SVK::$name";
    Class::MOP::load_class($class);
    @multi{$class->mvp_multivalue_args} = ();
}

sub mvp_multivalue_args { keys %multi; }

sub bundle_config {
    my ($self, $section) = @_;
    #my $class = ( ref $self ) || $self;
    my $arg   = $section->{payload};

    my @config;

    for my $name (@names) {
        my $class = "Dist::Zilla::Plugin::SVK::$name";
        my %payload;
        foreach my $k (keys %$arg) {
            $payload{$k} = $arg->{$k} if $class->can($k);
        }
        push @config, [ "$section->{name}/$name" => $class => \%payload ];
    }

    return @config;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;


=pod

=head1 NAME

Dist::Zilla::PluginBundle::SVK - all SVK plugins in one go

=head1 VERSION

version 0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [@SVK]
    changelog   = Changes             ; this is the default
    allow_dirty = dist.ini            ; see SVK::Check...
    allow_dirty = Changes             ; ... and SVK::Commit
    commit_msg  = v%v%n%n%c           ; see SVK::Commit
    tag_format  = %v                  ; see SVK::Tag
    tag_message = %v                  ; see SVK::Tag
	tag_directory = tag               ; see SVK::Tag
    push_to     = origin              ; see SVK::Push # not ported

=head1 DESCRIPTION

This is a plugin bundle to load all svk plugins. It is equivalent to:

    [SVK::Check]
    [SVK::Commit]
    [SVK::Tag]
    [SVK::Push]

The options are passed through to the plugins.

=for Pod::Coverage bundle_config
    mvp_multivalue_args

=head1 AUTHOR

Dr Bean <drbean at (a) cpan dot (.) org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dr Bean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

