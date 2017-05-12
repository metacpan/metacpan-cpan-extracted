package Language::AttributeGrammar::Parser;

use strict;
use warnings;
no warnings 'uninitialized';

use Language::AttributeGrammar::Engine;
use Parse::RecDescent;
use Scalar::Util qw<reftype>;
use Carp::Clan '^Language::AttributeGrammar';

my $prefix = 'Language::AttributeGrammar::Parser';

our $AUTOACTION = q {
    if    ($item[0] eq 'TOKEN') { 1 }
    elsif (@item == 2)          { $item[1] }
    elsif ($item{TOKEN})        { 
        bless { value => $item[2], thisline => $thisline } => "$prefix\::$item[0]";
    }
    else {
        bless { %item, thisline => $thisline } => "$prefix\::$item[0]";
    }
};

our $SKIP = qr/(?: \s+ | (?: \# .*? \n ) )*/x;

our $GRAMMAR = <<'#\'END_GRAMMAR';   # vim hack
#\

{
    our $prefix = 'Language::AttributeGrammar::Parser';
}

grammar: attrsdef(s?) /\z/
    { bless { attrsdefs => $item[1] } => "$prefix\::$item[0]"; }

attrsdef: case ':' attrdef(s? /\|/)
    { bless { case => $item[1], attrdefs => $item[3] } => "$prefix\::$item[0]"; }
       | <error>

attrdef: attrcall '=' attrblock

attrcall: target '.' attr
        | <error>

target: self | child | special

attrblock: TOKEN <perl_codeblock>
         | <error>

case:    TOKEN /(?: :: )? \w+ (?: :: \w+ )*/x
attr:    TOKEN /\w+/
self:    TOKEN '$/'
child:   TOKEN /\$<\w+>/
special: TOKEN /`.*?`/

TOKEN:  # null

#'END_GRAMMAR

my $namecount = '0';

sub _get_child {
    my ($self, $child, $at) = @_;
    if ($self->can($child)) { $self->$child }
    elsif (reftype($self) eq 'HASH' && exists $self->{$child}) {
        $self->{$child};
    }
    else {
        croak "Cannot find a way to access $child of $self at $at";
    }
}

sub _filter_direct {
    my ($code, $at) = @_;
    $code =~ s[\$/][\$_AG_SELF]gx;
    $code =~ s[\$<(\w+)>][Language::AttributeGrammar::Parser::_get_child(\$_AG_SELF, '$1', '$at')]gx;
    $code;
}

sub _filter_code {
    my ($target, $attr, $code, $at) = @_;
    my $result;
    my $idxa = sub {
        my ($itarget, $iattr) = @_;
        my $id = '$_AG_N' . $namecount++;
        $result .= "my $id = \$_AG_ATTR->get($itarget)->get('$iattr');\n";
        "$id->get('$iattr', '$at')";
    };

    my $idxarray = sub {
        my ($itarget, $iattr) = @_;
        my $id = '@_AG_N' . $namecount++;
        $result .= "my $id = map { \$_AG_ATTR->get(\$_)->get('$iattr') } $itarget;\n";
        "(map { \$_->get('$iattr', '$at') } $id)";
    };
        
    $code =~ s[\$/ \s* \. \s* (\w+)]      
              [$idxa->('$_AG_SELF', $1)]gex;
    $code =~ s[\$<(\w+)> \s* \. \s* (\w+)]
              [$idxa->("Language::AttributeGrammar::Parser::_get_child(\$_AG_SELF, '$1', '$at')", $2)]gex;
    $code = _filter_direct($code, $at);
    $code =~ s[`(.*?)` \s* \. \s* (\w+)]
              [$idxarray->($1, $2)]gex;
    
    $result .= "\$_AG_ATTR->get($target)->get('$attr')->set(sub $code, '$attr', '$at');\n";
    $result;
}

# use an attribute grammar to process the attribute grammar grammar
our $ENGINE = Language::AttributeGrammar::Engine->new;

add_visitor $ENGINE "$prefix\::grammar" => sub {
    my ($self, $attrs) = @_;
    
    my $prefix = $attrs->get($self)->get('prefix');
    for (@{$self->{attrsdefs}}) {
        $attrs->get($_)->get('prefix')->set(sub { $prefix->get });
    }
    my @defthunks = map { $attrs->get($_)->get('defthunks') } @{$self->{attrsdefs}};
    my @cases = map { $attrs->get($_)->get('case') } @{$self->{attrsdefs}};

    $attrs->get($self)->get('engine')->set(sub {
        my %visitors;
        for my $defs (@defthunks) {
            for my $def (@{$defs->get}) {
                my $case = $def->{case}->get;
                $visitors{$case} ||= "my (\$_AG_SELF, \$_AG_ATTR) = \@_;\n";
                $visitors{$case} .= $def->{visitor}->get;
            }
        }


        my $engine = Language::AttributeGrammar::Engine->new;
        
        for my $case (@cases) {
            $engine->add_case($case->get);
        }
        
        for my $case (keys %visitors) {
            my $code = eval "sub {\n$visitors{$case}\n}" or croak $@;
            $engine->add_visitor($case => $code);
        }

        $engine;
    });
};

add_visitor $ENGINE "$prefix\::attrsdef" => sub {
    my ($self, $attrs) = @_;
    my $prefix = $attrs->get($self)->get('prefix');
    $attrs->get($self->{case})->get('prefix')->set(sub { $prefix->get });
    my $case = $attrs->get($self->{case})->get('name');
    for (@{$self->{attrdefs}}) {
        $attrs->get($_)->get('case')->set(sub { $case->get });
    }
    my @defthunks = map {
        {
            case    => $case,
            visitor => $attrs->get($_)->get('visitor'),
        }
    } @{$self->{attrdefs}};

    $attrs->get($self)->get('defthunks')->set(sub { \@defthunks });
    $attrs->get($self)->get('case')->set(sub { $case->get });
};

add_visitor $ENGINE "$prefix\::attrdef" => sub {
    my ($self, $attrs) = @_;
    my $target = $attrs->get($self->{attrcall})->get('target');
    my $attr   = $attrs->get($self->{attrcall})->get('attr');
    my $code   = $attrs->get($self->{attrblock})->get('code');
    $attrs->get($self)->get('visitor')->set(sub {
        _filter_code($target->get, $attr->get, $code->get, "grammar line $self->{thisline}");
    });
};

add_visitor $ENGINE "$prefix\::attrcall" => sub {
    my ($self, $attrs) = @_;
    my $invocant = $attrs->get($self->{target})->get('invocant');
    my $attr     = $attrs->get($self->{attr})->get('name');
    $attrs->get($self)->get('target')->set(sub { $invocant->get });
    $attrs->get($self)->get('attr')->set(sub { $attr->get });
};

add_visitor $ENGINE "$prefix\::attrblock" => sub {
    my ($self, $attrs) = @_;
    $attrs->get($self)->get('code')->set(sub { $self->{value} });
};

add_visitor $ENGINE "$prefix\::case" => sub {
    my ($self, $attrs) = @_;
    my $prefixa = $attrs->get($self)->get('prefix');
    $attrs->get($self)->get('name')->set(sub { 
        my $prefix = $prefixa->get;
        if ($self->{value} =~ /^::/) {
            $self->{value};
        }
        else {
            "$prefix$self->{value}";
        }
    });
};

add_visitor $ENGINE "$prefix\::attr" => sub {
    my ($self, $attrs) = @_;
    $attrs->get($self)->get('name')->set(sub { $self->{value} });
};

add_visitor $ENGINE "$prefix\::self" => sub {
    my ($self, $attrs) = @_;
    $attrs->get($self)->get('invocant')->set(sub { '$_AG_SELF' });
};

add_visitor $ENGINE "$prefix\::child" => sub {
    my ($self, $attrs) = @_;
    my ($name) = $self->{value} =~ /^\$<(\w+)>$/;
    $attrs->get($self)->get('invocant')->set(sub {
        "Language::AttributeGrammar::Parser::_get_child(\$_AG_SELF, '$name', 'grammar line $self->{thisline}')"
    });
};

add_visitor $ENGINE "$prefix\::special" => sub {
    my ($self, $attrs) = @_;
    my ($code) = $self->{value} =~ /^`(.*)`$/;
    $code = _filter_direct($code, $self->{thisline});
    $attrs->get($self)->get('invocant')->set(sub { $code });
};

$ENGINE->make_visitor('visit');


our $PARSER;
{
    local $Parse::RecDescent::skip = $SKIP;
    local $::RD_AUTOACTION = $AUTOACTION;
    $PARSER = Parse::RecDescent->new($GRAMMAR);
}

sub new {
    my ($class, $grammar, $prefix) = @_;
    $prefix ||= '';
    my $tree = $PARSER->grammar($grammar) or croak "Parse error";
    return $ENGINE->evaluate('visit', $tree, 'engine', {
        prefix => $prefix,
    });
}
