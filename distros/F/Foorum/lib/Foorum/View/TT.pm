package Foorum::View::TT;

use strict;
our $VERSION = '1.001000';
use base 'Catalyst::View::TT';
use Template::Stash::XS;
use File::Spec;

#use Template::Constants qw( :debug );
use HTML::Email::Obfuscate;
use Foorum::Utils qw/decodeHTML be_url_part/;
use Locale::Country::Multilingual;
use vars qw/$lcm $Email/;

my $tmpdir = File::Spec->tmpdir();
$lcm   = Locale::Country::Multilingual->new();
$Email = HTML::Email::Obfuscate->new();

__PACKAGE__->config(

    #DEBUG        => DEBUG_PARSER | DEBUG_PROVIDER,
    INCLUDE_PATH => [
        Foorum->path_to( 'templates', 'custom' ),
        Foorum->path_to('templates')
    ],
    TEMPLATE_EXTENSION => '.html',
    COMPILE_DIR        => File::Spec->catdir( $tmpdir, 'ttcache', $< ),
    COMPILE_EXT        => '.ttp1',
    STASH              => Template::Stash::XS->new,
    FILTERS            => {
        email_obfuscate => sub               { $Email->escape_html(shift) },
        decodeHTML      => sub               { decodeHTML(shift) },
        be_url_part     => sub               { be_url_part(shift) },
        code2country    => [ \&code2country, 1 ],
    }
);

sub code2country {
    my ( $context, $lang ) = @_;
    $lcm->set_lang($lang);
    return sub {
        my $code = shift;
        return $lcm->code2country($code);
        }
}

sub render {
    my $self = shift;
    my ( $c, $template, $args ) = @_;

    # view Catalyst::View::TT for more details
    my $vars = { ( ref $args eq 'HASH' ? %$args : %{ $c->stash() } ), };

    if ( $vars->{no_wrapper} ) {
        $self->template->service->{WRAPPER} = [];
    } else {
        $self->template->service->{WRAPPER} = ['wrapper.html'];
    }

    return $self->next::method(@_);
}

1;
__END__

=pod

=head1 NAME

Foorum::View::TT - Template for Foorum

=head1 SEE ALSO

L<Catalyst::View::TT>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
