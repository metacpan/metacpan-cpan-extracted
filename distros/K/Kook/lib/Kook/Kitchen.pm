###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'misc';     # suppress warning "Can't locate package Cookable" (for Perl 5.8)
no warnings 'syntax';   # suppress warning "Can't locate package Cookable" (for Perl 5.10 or later)


##
## create cooking object tree and invoke recipe methods.
##
## ex.
##   my $cookbook = Kook::Cookbook->new("Kookbook.py");
##   my $kitchen = Kook::Kitchen->new($cookbook);
##   my $argv = ["hello.o", "-h", "-v"];
##   $kitchen->start_cooking($argv);   # recipe is invoked and "hello.o" will be created
##
package Kook::Kitchen;
use Exporter ('import');
our @EXPORT_OK = ('Kitchen');
use Data::Dumper;

use Kook::Config;

sub new {
    my ($class, $cookbook, $properties) = @_;
    my $this = {
        cookbook => $cookbook,
        properties => $properties,
    };
    return bless($this, $class);
}

sub create_cooking_tree {
    my ($this, $target_product, $cookables) = @_;
    $cookables = {} unless defined $cookables;
    my $cookbook = $this->{cookbook};
    my $root = $this->_create_cooking_tree($cookbook, $target_product, $cookables);
    return $root;
}

sub _create_cooking_tree {
    my ($this, $cookbook, $target, $cookables, $parent_product) = @_;
    return $cookables->{$target} if ($cookables->{$target});
    my $cookable;
    if ($cookbook->material_p($target)) {
        -f $target  or die "$target: material not found.";
        $cookable = Kook::Material->new($target);
    }
    else {
        my $recipe = $cookbook->find_recipe($target);
        if    ($recipe)    { $cookable = Kook::Cooking->new($target, $recipe); }
        elsif (-f $target) { $cookable = Kook::Material->new($target); }
        else {
            $parent_product ? die "$target: no such recipe or material (required for '$parent_product').\n"
                            : die "$target: no such recipe or material.\n";
        }
    }
    #assert $cookable;
    $cookables->{$target} = $cookable;
    if ($cookable->{ingreds}) {
        for my $ingred (@{$cookable->{ingreds}}) {
            #python: if isinstance(ingred, ConditionalFile):
            #python:     filename = ingred()
            #python:     if not filename: continue
            #python:     ingred = filename
            #python: if isinstance($ingred, IfExists):
            #python:     if not exists(ingred.filename): continue
            my $child_cookable = $this->_create_cooking_tree($cookbook, $ingred, $cookables, $target);
            push(@{$cookable->{children}}, $child_cookable);
        }
    }
    return $cookable;
}

## die if tree has a loop
sub check_cooking_tree {
    my ($this, $root) = @_;
    return unless $root->{children};
    my $route = [];
    my $visited = {};
    my $errmsg = $this->_check_cooking_tree($root, $route, $visited);
    ! $errmsg  or die "$root->{product}: $errmsg";
    #assert $#route == -1;
    #assert $#visited == -1;
}

sub _check_cooking_tree {
    my ($this, $cooking, $route, $visited) = @_;
    push(@$route, $cooking->{product});
    $visited->{$cooking->{product}} = 1;
    for my $child (@{$cooking->{children}}) {
        my $prod = $child->{product};
        if (exists($visited->{$prod})) {
            my $i = 0;
            for my $item (@$route) {
                last if $item eq $child->{product};
                $i++;
            }
            my $len = @$route;
            my @looped = @$route[$i..$len-1];
            push(@looped, $child->{product});
            my $s = join "->", @looped;
            return "recipe is looped ($s).\n";
        }
        elsif ($child->{children}) {
            #assert $child->isa(Cooking)
            my $errmsg = $this->_check_cooking_tree($child, $route, $visited);
            return $errmsg if $errmsg;
        }
    }
    #assert $#route >= 0
    my $prod = pop @$route;
    #assert $prod eq $cooking->{product};
    #assert exists $visited->{$prod}
    delete $visited->{$prod};
    return;
}

sub start_cooking {
    my ($this, $target, @argv) = @_;
    $target  or die "start_cooking(): target is required.";
    ## create tree of cookable object
    my $root = $this->create_cooking_tree($target);
    $this->check_cooking_tree($root);
    #assert $root->isa(Cookable);
    #assert $root->{product} eq $target;
    ! $root->isa('Kook::Material')  or
        die "$target: is a material (= a file to which no recipe matched).";
    ## start cooking
    $root->cook(1, \@argv);
}


###
### abstract class for Cooking and Material.
###
package Kook::Cookable;

sub cook {
    my ($this, $depth, $argv, $parent_mtime) = @_;
    die "cook(): not implemented yet.";
}

sub has_product_file {
    my ($this) = @_;
    die "has_product_file(): not implemented yet.";
}

our $CONTENT_CHANGED = 3;     # recipe is invoked, and product content is changed when recipe is FileRecipe
our $MTIME_UPDATED   = 2;     # file content of product is not changed (recipe may be invoked or not)
our $NOT_INVOKED     = 1;     # recipe is not invoked (= skipped), for example product is newer than all ingredients


###
### represents material file.
###
package Kook::Material;
our @ISA = ('Cookable');

use Kook::Misc ('_debug');

sub new {
    my ($class, $filename) = @_;
    my $this = {
        product => $filename,
    };
    return bless($this, $class);
}

sub cook {
    my ($this, $depth, $argv) = @_;
    #assert -f $this->{product};
    _debug("material '$this->{product}'", $depth);
    return $NOT_INVOKED;
}

sub has_product_file {
    my ($this) = @_;
    return 1;
}


###
### represens recipe invocation. in other words, Recipe is 'definition', Cooking is 'execution'.
###
package Kook::Cooking;
our @ISA = ('Cookable');
use Data::Dumper;
use File::Temp ('tempfile');
use File::Compare ('compare');

use Kook;
use Kook::Misc ('_debug', '_trace', '_report_msg', '_report_cmd');

sub new {
    my ($class, $target, $recipe) = @_;
    my $product = $target;
    my @ingreds = $recipe->{ingreds} ? @{$recipe->{ingreds}} : ();
    my @byprods = $recipe->{byprods} ? @{$recipe->{byprods}} : ();
    my @coprods = $recipe->{coprods} ? @{$recipe->{coprods}} : ();
    my @spices  = $recipe->{spices}  ? @{$recipe->{spices}}  : ();
    my $m = [];
    if ($recipe->{pattern}) {
        ## TODO: support if_exists()
        my $pat = $recipe->{pattern};
        $target =~ $pat  or die "$target: not matched to '$pat'.";
        $m = [$&, $1, $2, $3, $4, $5, $6, $7, $8, $9];
        @ingreds = map { s/\$\((\d+)\)/$m->[$1]/ge; $_ } @ingreds;
        @byprods = map { s/\$\((\d+)\)/$m->[$1]/ge; $_ } @byprods;
        @coprods = map { s/\$\((\d+)\)/$m->[$1]/ge; $_ } @coprods;
    }
    my $this = {
        product  => $product,
        ingreds  => \@ingreds,
        byprods  => \@byprods,
        coprods  => \@coprods,
        ingred   => $ingreds[0],
        byprod   => $byprods[0],
        coprod   => $coprods[0],
        spices   => \@spices,
        recipe   => $recipe,
        "m"      => $m,
        cooked   => undef,
        argv     => [],
        children => [],
    };
    return bless($this, $class);
}

sub has_product_file {
    my ($this) = @_;
    return $this->{recipe}->{kind} eq "file";
}

##
## pseudo-code:
##
##   if CONENT_CHANGED in self.children:
##     invoke recipe
##     if new content is same as old:
##       return MTIME_UPDATED
##     else:
##       return CONTENT_CHANGED
##   elif MTIME_UPDATED in self.children:
##     # not invoke recipe function
##     touch product file
##     return MTIME_UPDATED
##   else:
##     # not invoke recipe function
##     return NOT_INVOKED
##
sub cook {
    my ($this, $depth, $argv) = @_;
    my $is_file_recipe = $this->{recipe}->{kind} eq "file";
    my $product = $this->{product};
    ## return if already cooked
    if ($this->{cooked}) {
        _debug("pass $product (already cooked)", $depth);
        return $this->{cooked};
    }
    ## get mtime of product file if it exists
    _debug("begin $product", $depth);
    my $product_mtime = $is_file_recipe && -f $product ? (stat $product)[9] : 0;
    ## invoke ingredients' recipes
    my $child_status = $NOT_INVOKED;
    if ($this->{children}) {
        for my $child (@{$this->{children}}) {
            my $ret = $child->cook($depth+1, []);
            #assert $ret;
            $child_status = $ret if $ret > $child_status;
            if ($product_mtime && $ret == $NOT_INVOKED && $child->has_product_file()) {
                #assert -f $child->{product};
                if ((stat $child->{product})[9] > $product_mtime) {
                    _trace("child file '$child->{product}' is newer than product '$this->{product}'.", $depth);
                    $child_status = $CONTENT_CHANGED;
                }
            }
        }
    }
    ## there are some cases to skip recipe invocation (ex. product is newer than ingredients)
    my $sig = $this->_signature();
    if ($this->_can_skip($child_status, $depth)) {
        if ($child_status == $MTIME_UPDATED) {
            #assert -f $product;
            _report_msg("$product $sig", $depth);
            _debug("touch and skip $product ($sig)", $depth);
            _report_cmd("touch $product   # skipped");
            my $now = time();
            utime $now, $now, $product;
            return $this->{cooked} = $MTIME_UPDATED;
        }
        elsif ($child_status == $NOT_INVOKED) {
            _debug("skip $product ($sig)", $depth);
            return $this->{cooked} = $NOT_INVOKED;
        }
        else {
            #assert $child_status == Kook::Cookable::CONTENT_CHANGED;
            ## don't skip recipe invocation
        }
    }
    ## invoke recipe function
    my $ret;
    my $tmp_filename;
    eval {
        ## if product file exists, rename it to temporary filename
        if ($product_mtime) {
            my ($tmp_fh, $tmp_fname) = tempfile();
            close $tmp_fh;
            $tmp_filename = $tmp_fname;
            rename $product, $tmp_filename;
            _trace("product '$product' is renamed to '$tmp_filename'");
        }
        ## invoke recipe
        my $s = $is_file_recipe ? 'create' : 'perform';
        _debug("$s $product ($sig)", $depth);
        _report_msg("$product ($sig)", $depth);
        $this->_invoke_recipe_with($argv);
        ## check whether product file created or not
        if ($is_file_recipe && ! $Kook::Config::NOEXEC && ! -f $product) {
            die "$product: product not creatd ($sig).";
        }
        ## if new product file is same as old, return MTIME_UPDATED, else return CONTENT_CHANGED
        my $msg;
        if ($Kook::Config::COMPARE_CONTENTS && $product_mtime && compare($product, $tmp_filename) == 0) {
            $ret = $MTIME_UPDATED;
            $msg = "end $product (content not changed, mtime updated)";
        }
        else {
            $ret = $CONTENT_CHANGED;
            $msg = "end $product (content changed)";
        }
        _debug($msg, $depth);
    };
    if ($tmp_filename && -f $tmp_filename) {
        unlink $tmp_filename;
        _trace("temporary file '$tmp_filename' is removed.");
    }
    if ($@) {
        if ($product_mtime) {
            _report_msg("(remove $product because unexpected error thrown ($sig)", $depth);
            unlink $product if -f $product;
        }
        die $@;
    }
    return $this->{cooked} = $ret;
}

sub _signature {
    my ($this) = @_;
    return "recipe=".$this->{recipe}->{product};   # signature
}

sub _can_skip {
    my ($this, $child_status, $depth) = @_;
    my $product = $this->{product};
    if ($Kook::Config::FORCED) {
        #_trace("cannot skip: invoked forcedly.", $depth);
        return 0;
    }
    if ($this->{recipe}->{kind} eq "task") {
        _trace("cannot skip: task recipe should be invoked in any case.", $depth);
        return 0;
    }
    unless (@{$this->{children}}) {
        _trace("cannot skip: no children for product '$product'.", $depth);
        return 0;
    }
    unless (-e $this->{product}) {
        _trace("cannot skip: product '$product' not found.", $depth);
        return 0;
    }
    #
    if ($child_status == $CONTENT_CHANGED) {
        _trace("cannot skip: there is newer file in children than product '$product'.", $depth);
        return 0;
    }
    #if ($child_status == $NOT_INVOKED) {
    #    my $timestamp = (stat $product)[9];
    #    for my $child (@{$this->{children}}) {
    #        my $child_has_product_file = ! ($child->{recipe} && $child->{recipe}->{kind} eq "task");
    #        if ($child_has_product_file && (stat $child->{product})[9] > $timestamp) {
    #            print("cannot skip: child '$child->{product}' is newer than product '$product'.\n");
    #            _trace("cannot skip: child '$child->{product}' is newer than product '$product'.", $depth);
    #            return 0;
    #        }
    #    }
    #}
    #
    _trace("recipe for '$product' can be skipped.", $depth);
    return 1;
}

sub _invoke_recipe_with {
    my ($this, $argv) = @_;
    return unless $this->{recipe}->{method};
    $this->{argv} = $argv;
    if (@{$this->{spices}}) {
        my ($opts, $rests) = $this->parse_cmdopts($argv);
        #$this->{opts}  = $opts;
        #$this->{rests} = $rests;
        $this->{recipe}->{method}->($this, $opts, $rests);
    }
    else {
        $this->{recipe}->{method}->($this, undef, $argv);
    }
}

sub parse_cmdopts {
    my ($this, $argv) = @_;
    my $sig = $this->_signature();
    my $parser = $Kook::Config::CMDOPT_PARSER_CLASS->new($this->{spices});
    my ($opts, $rests) = $parser->parse($argv);
    _trace("parse_cmdopts() ($sig): opts=$opts, rests=$rests");
    return $opts, $rests;
}


1;
