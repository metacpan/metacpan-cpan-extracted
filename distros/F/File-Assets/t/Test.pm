package t::Test;

use strict;
use warnings;

use File::Assets;
use Directory::Scratch;
use Test::Memory::Cycle;
use Test::More;
use HTML::Declare qw/LINK SCRIPT STYLE/;
use base qw/Exporter/;
use vars qw/@EXPORT/;
@EXPORT = qw/compare/;

my $scratch;
sub scratch {
    return $scratch ||= do {
        t::Test::Scratch->new;
    }
}

my $assets;
sub assets {
    shift;
    memory_cycle_ok($assets) if $assets;
    return $assets = File::Assets->new(base => [ "http://example.com/", scratch->base, "/static" ], @_);
}

sub compare ($;@) {
    my $expect = shift;
    my @content;
    while (@_) {
        my %attributes;
        if (! ref $_[0]) {
            my $href = shift;
            my $kind;
            $kind = $1 if $href =~ s/^([\w-]+);//;
            ($kind) = $href =~ m/\.([^.]+)$/ unless $kind;
            %attributes = (%attributes, %{ shift() }) if ref $_[0] eq "HASH";
            if ($kind eq "js") {
                push @content, SCRIPT({ type => "text/javascript", src => $href, _ => "", %attributes });
            }
            elsif ($kind =~ m/^css\b/) {
                my ($type, $media) = split m/-/, $kind;
                $attributes{media} = $media if defined $media;
                push @content, LINK({ rel => "stylesheet", type => "text/css", href => $href, %attributes });
            }
        }
        elsif (ref $_[0] eq "ARRAY") {
            my ($kind, $content, $attributes) = @{ shift() };
            $attributes ||= {};
            %attributes = (%attributes, %$attributes);
            if ($kind eq "js") {
                push @content, SCRIPT({ type => "text/javascript", _ => "\n$content" });
            }
            elsif ($kind =~ m/^css\b/) {
                my ($type, $media) = split m/-/, $kind;
                push @content, STYLE({ type => "text/css", _ => "\n$content" });
            }
        }
        else {
            die "Don't understand: @_";
        }
    }
    return is($expect, join "\n", @content);
}

END {
    memory_cycle_ok($assets) if Test::Builder->new->{Have_Plan};
}

package t::Test::Scratch;

use base qw/Directory::Scratch/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_, CLEANUP => 0);
    $self->create_tree({
        (map { $_ => "/* Test file: $_ */\n" } qw(
            static/css/apple.css
            static/css/banana.css
            static/js/apple.js
            js/grape.js
            js/plum.js
            css/grape.css
            other/pear.js
        )),
        'static/css/cherry.css' => <<_END_,
div.cherry {
    font-weight: bold;
    /* Some comment */
    font-weight: 100;
    border: 1px solid #aaaaaa;
}

div.cherry em {
    color: red;
}
_END_
        
        'static/js/cherry.js' => <<_END_,
(function(){
    alert("Nothing happens.");

    var cherry = 1 + 2;

    /* Nothing happens */
    return function(alpha, beta, delta) {
        return alpha + beta + delta;
    } 

}());
_END_
        'static/css/grape.css' => <<_END_,
/* This is grape.css */
_END_
    });

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->cleanup;
    $self->SUPER::DESTROY;
}

package File::Assets::Filter::TestCollect;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect/;

sub build_content {
    my $self = shift;

    return \"/* Everything is replaced with this! */"
}

package File::Assets::Filter::Test;

use strict;
use warnings;

use base qw/File::Assets::Filter/;

1;

