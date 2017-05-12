package MIME::Expander::Plugin;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use parent qw(Class::Data::Inheritable);
use Email::MIME;

__PACKAGE__->mk_classdata('ACCEPT_TYPES' => [qw(
    )]);

sub new {
    my $class = shift;
    bless {}, (ref $class || $class);
}

sub is_acceptable {
    my $self        = shift;
    my $type        = shift or return ();
    for ( @{$self->ACCEPT_TYPES} ){
        return 1 if( $type eq $_ );
    }
    return ();
}

sub expand {
    my $self        = shift;
    my $part        = shift;
    my $callback    = shift;
    my $c           = 0;

    $callback->( $part->body )
        if( ref $callback eq 'CODE' );

    ++$c;

    return $c;
}

1;
__END__


=pod

=head1 NAME

MIME::Expander::Plugin - Abstract class for plugin of MIME::Expander

=head1 SYNOPSIS

    # An implement class
    package MIME::Expander::Plugin::MyExpander;
    use parent qw(MIME::Expander::Plugin);
    
    # This plugin has to be implemented class data 'ACCEPT_TYPES'
    # to negotiate for acceptable type
    __PACKAGE__->mk_classdata('ACCEPT_TYPES' => [qw(
        type/sub-type
        )]);

    # And expand() for determine type
    sub expand {
        my $self        = shift;
        my $part        = shift;
        my $callback    = shift;
        my $count       = 0;

        my $contents = $part->body;
        while( my $media = your_expand_function( $contents ) ){
            my $data     = $media->{data};
            my $filename = $media->{name};
            $callback->( \ $contents, {
                filename => $filename, # optional, sometimes it is undef
                });
            ++$count;
        }

        # number of expanded contents
        return $count;
    }

=head1 DESCRIPTION

MIME::Expander::Plugin is an abstract class for plugin of MIME::Expander.

Each plugins extended this class have to expand
the contents of ACCEPT_TYPES and passes each to the callback.

=head1 SEE ALSO

L<MIME::Expander>

L<Class::Data::Inheritable>

=cut
