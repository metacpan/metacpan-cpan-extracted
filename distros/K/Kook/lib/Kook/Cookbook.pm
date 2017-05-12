###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;


package Kook::Cookbook;
use Data::Dumper;

use Kook::Util;
use Kook::Sandbox;
use Kook::Misc ('_debug', '_trace');
use Kook::Util ('repr');

sub new {
    my ($class, $bookname, $properties) = @_;
    my $this = {
        bookname              => $bookname,
        specific_task_recipes => [],
        generic_task_recipes  => [],
        specific_file_recipes => [],
        generic_task_recipes  => [],
        materials             => [],
        property_tuples       => [],
        default               => undef,
        desc                  => undef,
    };
    $this = bless $this, $class;
    $this->load_file($bookname, $properties) if $bookname;
    return $this;
}

sub default_product {
    my ($this) = @_;
    #return $this->{context}->{kook_default_product};
    #return $Kook::default_product;
    return $this->{default};
}

sub load_file {
    my ($this, $filename, $properties) = @_;
    $this->{bookname} = $filename;
    -f $filename  or die "$filename: not found.\n";
    my $content = Kook::Util::read_file($filename);
    $this->load($content, $filename, $properties);
}

sub load {
    my ($this, $content, $bookname, $properties) = @_;
    $bookname = '(kook)' if ! $bookname;
    Kook::Sandbox::_eval($content, $bookname, $properties);
    ! $@  or die("[ERROR] kookbook has error:\n$@\n");
    $this->{property_tuples} = \@Kook::Sandbox::_property_tuples;
    $this->{default} = $Kook::Sandbox::kook_default if $Kook::Sandbox::kook_default;  # for backward compatibility
    $this->{desc}    = $Kook::Sandbox::kook_desc    if $Kook::Sandbox::kook_desc;     # for backward compatibility
    my $kook = $Kook::Sandbox::kook;
    $this->{default} = $kook->{default} if $kook->{default};
    $this->{desc}    = $kook->{desc}    if $kook->{desc};
    ## masks
    my $TASK     = 0x0;
    my $FILE     = 0x1;
    my $SPECIFIC = 0x0;
    my $GENERIC  = 0x2;
    ## create recipes
    my $recipes = [
        [],    # SPECIFIC | TASK
        [],    # SPECIFIC | FILE
        [],    # GENERIC  | TASK
        [],    # GNERIC   | FILE
    ];
    ## TODO: materials
    for my $recipe (@Kook::Sandbox::_recipes) {
        my $flag = $recipe->{kind} eq 'task' ? $TASK : $FILE;
        $flag = $flag | ($recipe->{pattern} ? $GENERIC : $SPECIFIC);
        push @{$recipes->[$flag]}, $recipe;
    }
    $this->{specific_task_recipes} = $recipes->[$SPECIFIC | $TASK];  ## TODO: use dict
    $this->{specific_file_recipes} = $recipes->[$SPECIFIC | $FILE];  ## TODO: use dict
    $this->{generic_task_recipes}  = $recipes->[$GENERIC  | $TASK];  ## TODO: support priority
    $this->{generic_file_recipes}  = $recipes->[$GENERIC  | $FILE];  ## TODO: support priority
    if ($Kook::Config::DEBUG_LEVEL >= 2) {
        _trace("specific task recipes: " . $this->_repr_products($this->{specific_task_recipes}));
        _trace("specific file recipes: " . $this->_repr_products($this->{specific_file_recipes}));
        _trace("generic  task recipes: " . $this->_repr_products($this->{generic_task_recipes}));
        _trace("generic  file recipes: " . $this->_repr_products($this->{generic_file_recipes}));
    }
}

sub _repr_products {
    my ($this, $recipes) = @_;
    my @names = map { $_->{product} } @$recipes;
    return repr(\@names);
}

sub material_p {
    my ($this, $target) = @_;
    for my $item (@{$this->{materials}}) {
        return 1 if $item eq $target;
    }
    return 0;
}

sub find_recipe {
    my ($this, $target) = @_;
    my $recipes_tuple = [
        $this->{specific_task_recipes},
        $this->{specific_file_recipes},
        $this->{generic_task_recipes},
        $this->{generic_file_recipes},
    ];
    for my $recipes (@$recipes_tuple) {
        for my $recipe (@$recipes) {
            if ($recipe->match($target)) {
                my $recipe_name = $recipe->{name} || '';
                _debug("Cookbook#find_recipe(): target=$target, func=$recipe_name, product=$recipe->{product}", 2);
                return $recipe;
            }
        }
    }
}


1;
