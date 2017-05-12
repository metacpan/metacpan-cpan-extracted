package Mason::Plugin::WithEncoding::Test::Class;

use utf8;

# http://www.effectiveperlprogramming.com/2011/07/fix-testbuilders-unicode-issue/
binmode Test::More->builder->output(),         ':encoding(UTF-8)';
binmode Test::More->builder->failure_output(), ':encoding(UTF-8)';

use Test::Class::Most parent => 'Poet::Test::Class';
use Poet::Tools qw(dirname mkpath trim write_file);
use URI::Escape;
use Encode qw(encode decode);

sub mech {
    my $self = shift;
    my $poet = shift;
    my $mech = $self->SUPER::mech( env => $poet );
    @{ $mech->requests_redirectable } = ();
    return $mech;
}

sub add_comp {
    my ( $self, %params ) = @_;
    my $path = $params{path} or die "must pass path";
    my $src  = $params{src}  or die "must pass src";
    my $file = $params{poet}->comps_dir . $path;
    mkpath( dirname($file), 0, '0775' );
    write_file( $file, $src );
}

# Encode the content because it is leaving Perl (which uses its own
# internal character representation) and being sent to the system for
# storage. When Mason reads the component source back again, the 'use utf8;'
# added to comp headers will decode the source back into internal Perly format.
# Then the WithEncoding plugin will encode content sent back out, as utf8 (in this
# case, but in general as whatever is configured).
sub add_comps {
    my $self = shift;
    my $poet = shift;
    # Don't encode the path because, hmm, not sure. Because it 'just works' as-is.
    $self->add_comp(path => '/♥♥♥.mc',   src => encode('UTF-8', $self->content_for_tests('utf8')),  poet => $poet);
    $self->add_comp(path => '/utf8.mc',  src => encode('UTF-8', $self->content_for_tests('utf8')),  poet => $poet);
    $self->add_comp(path => '/plain.mc', src => encode('UTF-8', $self->content_for_tests('plain')), poet => $poet);
    $self->add_comp(path => '/dies.mc',  src => encode('UTF-8', $self->content_for_tests('dies')),  poet => $poet);
    $self->add_comp(path => '/json.mc',  src => encode('UTF-8', $self->content_for_tests('json')),  poet => $poet);
}

sub content_for_tests {
    my ($self, $want) = @_;

    my $src_utf8 = <<UTF8;
% sub { uc(\$_[0]) } {{
a quick brown fox jumps over the lazy dog.

διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα.
árvíztűrő tükörfúrógép.
dość gróźb fuzją, klnę, pych i małżeństw!
эх, чужак, общий съём цен шляп (юфть) – вдрызг!
kŕdeľ šťastných ďatľov učí pri ústí váhu mĺkveho koňa obhrýzať kôru a žrať čerstvé mäso.
zwölf boxkämpfer jagen viktor quer über den großen sylter deich.

% }}

QUERY STRING FROM REQ: <% \$m->req->query_string %>

% use URI::Escape;
QUERY STRING UNESCAPED: <% \$m->req->query_string %>

UTF8

    # I think if everything was running correctly, this wouldn't die:
    my $src_utf8_dies = <<UTF8;
<% \$.args->{♥} %>
UTF8

    my $src_plain = <<ASCII;
% sub { uc(\$_[0]) } {{

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent ut ante
mollis, ultricies arcu ut, convallis libero. Fusce a felis sapien. Aliquam
aliquam felis ut justo aliquam, non sollicitudin tellus porta. Etiam
sollicitudin, mi eu vulputate sagittis, elit arcu molestie leo, eget finibus
tortor risus ut quam. Aenean id dolor eros. Vestibulum dictum, sem vitae
molestie feugiat, enim quam ultricies metus, quis dapibus sapien orci ut risus.

% }}

QUERY STRING FROM REQ: <% \$m->req->query_string %>

% use URI::Escape;
QUERY STRING UNESCAPED: <% uri_unescape(\$m->req->query_string) %>

ASCII

    my $src_json = <<SRC;
<\%init>
    my \$data_for_json = {
        foo => 'bar',
        baz => [qw(barp beep)],
        9 => { one => 1, ex => 'EKS' },
        heart => '♥',
    };
</\%init>
% \$m->send_json(\$data_for_json);
SRC



    return $src_utf8        if $want eq 'utf8';
    return $src_plain       if $want eq 'plain';
    return $src_utf8_dies   if $want eq 'dies';
    return $src_json        if $want eq 'json';
    die "No content for '$want'";
}

1;
