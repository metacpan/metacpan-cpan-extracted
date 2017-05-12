package HTML::Feature::Engine;
use strict;
use warnings;
use HTML::Feature::Engine::TagStructure;
use HTML::Feature::Engine::LDRFullFeed;
use HTML::Feature::Engine::GoogleADSection;
use UNIVERSAL::require;
use Encode;
use Carp;
use base qw(HTML::Feature::Base);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->_setup;
    return $self;
}

sub run {
    my $self     = shift;
    my $html_ref = shift;
    my $url      = shift;
    my $c        = $self->context;
    my $result   = HTML::Feature::Result->new;
    eval {
        LABEL: for my $engine ( @{ $self->{engines} } )
        {
            $result = $engine->run( $html_ref, $url, $result );
            if ( $result->{matched_engine} ) {
                if ( defined $c->{enc_type} ) {
                    $result->title(
                        Encode::encode( $c->{enc_type}, $result->title ) );
                    $result->desc(
                        Encode::encode( $c->{enc_type}, $result->desc ) );
                    $result->text(
                        Encode::encode( $c->{enc_type}, $result->text ) );
                }
                last LABEL;
            }
        }
    };
    if ($@) {
        carp("can not parse data");
        return HTML::Feature::Result->new;
    }
    return $result;
}

sub _setup {
    my $self   = shift;
    my $c      = $self->context;
    my $config = $c->config;
    if ( !defined $config->{engines} || @{ $config->{engines} } < 1 ) {
        my $engine = HTML::Feature::Engine::TagStructure->new( context => $c );
        push( @{ $self->{engines} }, $engine );
    }
    else {
        for my $class ( @{ $config->{engines} } ) {
            unless ( $class->can('new') ) {
                $class->require or die $@;
            }
            my $engine = $class->new( context => $c );
            push( @{ $self->{engines} }, $engine );
        }
    }
}

1;
__END__

=head1 NAME

HTML::Feature::Engine -

=head1 SYNOPSIS

  use HTML::Feature::Engine;

=head1 DESCRIPTION

HTML::Feature::Engine is

=head1 METHODS

=head2 new

=head2 run

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
