###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;


package Kook::Recipe;
use Data::Dumper;

our $DEFAULT_DESCS = {
    "all"       => "cook all products",
    "clean"     => "remove by-products",
    "clear"     => "remove products and by-products",
    "help"      => "show help",
    "install"   => "install product",
    "setup"     => "setup configuration",
    "test"      => "do test",
    "uninstall" => "uninstall product",
};

sub new {
    my ($class, $product, $ingreds, $values) = @_;
    if (ref($ingreds) eq 'ARRAY') {    # short notation
        if    (! defined($values))     { $values = { ingreds => $ingreds }; }
        elsif (ref($values) eq 'HASH') { $values->{'ingreds'} = $ingreds;   }
        else { die "Recipe->new(): invalid datatype for 3rd argument."; }
    }
    elsif (ref($ingreds) eq 'HASH') {  # normal notation
        $values = $ingreds;
    }
    else {
        die "Recipe->new(): invalid datatype for 2nd argument.";
    }
    my %hash = %$values;
    ## pattern;
    my $pattern;
    if (Kook::Util::has_metachar($product)) {
        $pattern = Kook::Util::meta2rexp($product);
    }
    ## kind
    my $kind = $hash{kind};
    if ($kind) {
        $kind eq "task" || $kind eq "file"  or
            die "'$kind': invalid kind (expected 'task' or 'file').";
    } else {
        $hash{kind} = $product =~ /^[-_a-z0-9]+$/ ? 'task' : 'file';
    }
    ## desc
    unless (defined $hash{desc}) {
        my $desc = $DEFAULT_DESCS->{$product};
        $hash{desc} = $desc if $desc;
    }
    ##
    my $this = {
        product => $product,
        pattern => $pattern,
        kind    => delete $hash{kind},
        ingreds => delete $hash{ingreds},
        byprods => delete $hash{byprods},    # not used
        coprods => delete $hash{coprods},    # not used
        desc    => delete $hash{desc},
        spices  => delete $hash{spices},
        method  => delete $hash{method},
    };
    if (%hash) {
        my $keys = join ',', map { "'$_'" } keys %hash;
        die "$keys: unknown keys for recipe()."
    }
    ##
    return bless($this, $class);
}

sub match {
    my ($this, $target_product) = @_;
    return $this->{pattern} ? ($target_product =~ $this->{pattern})
                            : ($target_product eq $this->{product});
}


1;
