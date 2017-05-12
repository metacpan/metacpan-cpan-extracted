# NAME

FormValidator::Simple::Struct - Validation module for nested array ,hash ,scalar  like FormValidator::Simple

# VERSION

This document describes FormValidator::Simple::Struct version 0.18.

# SYNOPSIS

    use FormValidator::Simple::Struct;
    $v = FormValidator::Simple::Struct->new();
    $parameters = { id => 100};
    $rule = {id => 'INT'};
    $v->check($parameters , $rule)
    
    if($v->has_error){
        for my $error(@{$v->get_error}){
            die($error->{param_name} . ' is not ' . $error->{error});
        }
    }

# DESCRIPTION

    You can check some value types in Scalar , Arrayref , Hashref.

# Functions

## check

    $v = FormValidator::Simple::Struct->new();
    $v->check(111 , "INT"); # return true
    $v->check(111 , "STRING"); # return false and $v->has_error is true 
    $v->check([111 , 1222, 333] , ["INT"]);# return true
    $v->check({ key  => 'value'},{key=> "ASCII"});# return true
    $v->check([{id => 111,id2=> 22.2 },{id=> 1222 , id2=> 1.11},{id=> 333 , id2=> 44.44}] , [{id =>"INT",id2 => "DECIMAL"}]);# return true

## has\_error

    $v->check(
      {key =>  "abcdefghijklmnop" },
      {key => ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 15]]});
    if($v->has_error){
        # error handling routine
    }

## get\_error

    $v->check(
      {key =>  "abcdefghijklmnop" },
      {key => ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 15]]});
    if($v->has_error){
        use Data::Dumper;
        warn Dumper $v->get_error;
        #$VAR1 = [
        #  {
        #    'min_value' => 1,
        #    'error' => 'LENGTH',
        #    'position' => '$param->{hoge}',
        #    'max_value' => 15,
        #    'param_name' => 'hoge',
        #    'message' => 'LENGTH IS WRONG'
        #  }
        #];
    }

## INT

    # allow integer ; 10 , 0 , -10
    ok $v->check(
       {key =>  "1" },
       {key => "INT"});

## STRING

    # allow all Strings
    ok $v->check(
       ["111" , "abcde"],
       ["STRING"]);

## ASCII

    # allow Arabic number and alphabet and ascii symbols
    ok $v->check(
       ["111" , 'abcde!"#$%%()'],
       ["ASCII"]);
    
    # not allow multi bytes characters
    ng $v->check(
       [Non-ASCII character],
       ["ASCII"]);

## DECIMAL

    # allow integer and decimals ; 10 1,0 , 0 , -10 , -1.0
    ok $v->check(
       ["111" , "11.1" , "-11" , '0' , '-1.15'],
       ["DECIMAL"]);

## URL

    # allow ^http|^https
    ok $v->check(
       ["http://google.com" , 'https://www.google.com/'],
       ["URL"]);

    ng $v->check(
       ["git://google.com" , 'smb://www.google.com/'],
       ["URL"]);

## EMAIL

    this is base on Email::Valid;

## DATETIME

    # The following examples are followed. 
    ok $v->check([
        '%Y-%m-%d %H:%M:%S',
        '%Y/%m/%d %H:%M:%S',
        '%Y-%m-%d %H-%M-%S',
        '%Y/%m/%d %H-%M-%S',],
    ['DATETIME']);

## DATE

    # The following examples are followed. 
    ok $v->check([
       '%Y-%m-%d',
       '%Y/%m/%d'],
    ['DATE']);

## TIME

    # The following examples are followed. 
    ok $v->check([
       '%H-%M-%S',
       '%H-%M-%S'],
    ['TIME']);

## LENGTH

    # check value length
    $rule = ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 8]];
    ok $v->check(['a'] , $rule);
    ng $v->check(['abcdefghi'] , $rule);

    $rule = ["ASCII","NOT_BLANK" , ['LENGTH' , 4]];
    ng $v->check(['abc'] , $rule) # false 
    ok $v->check(['abcd'] , $rule) # true
    ng $v->check(['abcde'] , $rule) # false 

## BETWEEN

    # check value 
    $rule = ["INT",['BETWEEN' , 1 , 8]];
    ok $v->check([1] , $rule) # true
    ng $v->check([3.1] , $rule) # false not INT
    ok $v->check([5] , $rule) # true
    ng $v->check([7.9] , $rule) # false not INT 
    ok $v->check([8] , $rule) # true
    ng $v->check([9] , $rule) # false, input is over 8
    ng $v->check([0] , $rule) # false, input is under 1

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# AUTHOR

S2 <s2otsa59@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, S2. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
