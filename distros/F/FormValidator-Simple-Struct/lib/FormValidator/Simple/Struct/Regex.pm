package FormValidator::Simple::Struct::Regex;
use 5.008_001;
use strict;
use warnings;
use Email::Valid;
use Time::Piece;

our $VERSION = '0.18';

use base 'Exporter';
our @EXPORT= qw/NOT_BLANK INT ASCII STRING DECIMAL EMAIL DATETIME DATE TIME TINYINT URL LENGTH BETWEEN DIGIT_LENGTH BOOLEAN/;

sub NOT_BLANK{
    my $s = shift;
    if (defined $s and length($s) > 0 ){
        return 1;
    }

    !!$s;
}

sub INT{
    my $s = shift;
    return 1 unless $s;
    $s =~ m/^\d+$|^-\d+$/;
}

sub BOOLEAN{
    my $s = shift;
    $s = lc $s;
    
    my $allow_strings = {
        map{$_ => 1}qw/1 0 true false yes no /
    };
    return $allow_strings->{$s}
}

sub ASCII{
    my $s = shift;
    return 1 unless $s;
    $s =~ /^[\x21-\x7E]+$/;
}

sub STRING{
    my $s = shift;
    return 1 unless $s;
    1;
}

sub DECIMAL{
    my $s = shift;
    return 1 unless $s;
    $s =~ m/^\d+\.\d+$|^-\d+\.\d+$/ or INT($s); 
}

sub EMAIL{
    my $s = shift;
    return 1 unless $s;
    Email::Valid->address(-address => $s);
}

sub DATETIME{
    my $s = shift;
    return 1 unless $s;
    return 0 unless $s =~ m!^\d{4}(?:-|/)\d{2}(?:-|/)\d{2} \d{2}(?::|-)\d{2}(?::|-)\d{2}$!;
    eval{
        Time::Piece->strptime($s , "%Y-%m-%d %H:%M:%S");
    };
    if($@){
        eval{
            Time::Piece->strptime($s , "%Y/%m/%d %H:%M:%S");
        }
    }
    if($@){
        eval{
            Time::Piece->strptime($s , "%Y-%m-%d %H-%M-%S");
        }
    }
    if($@){
        eval{
            Time::Piece->strptime($s , "%Y/%m/%d %H-%M-%S");
        }
    }
    !$@
}

sub DATE{
    my $s = shift;
    return 1 unless $s;
    eval{
        Time::Piece->strptime($s , "%Y-%m-%d");
    };
    if($@){
        eval{
            Time::Piece->strptime($s , "%Y/%m/%d");
        }
    }
    if($@){
        eval{
            Time::Piece->strptime($s , "%Y-%m-%d");
        }
    }
    if($@){
        eval{
            Time::Piece->strptime($s , "%Y/%m/%d");
        }
    }
    !$@
}

sub TIME{
    my $s = shift;
    return 1 unless $s;
    $s =~ m/\d{2}-\d{2}-\d{2}|\d{2}:\d{2}:\d{2}/; 
}

sub TINYINT{
    my $s = shift;
    return 1 unless $s;
    return ($s eq "0" or $s eq "1");
}

sub LENGTH{
    my ($s , $min , $max) = @_;
    my $len = length($s);
    if($len == 0 or $len >= $min and $len <= $max){
        return 1;
    }else{
        return 0;
    }
}

sub DIGIT_LENGTH{
    my ($s , $integer , $decimal) = @_;
    my ($integer_value , $decimal_value) = $s =~ m/(\d+)\.(\d+)/;
    $integer_value ||= "";
    $decimal_value ||= "";

    if(length($integer_value) <= $integer && length($decimal_value) <= $decimal){
        return 1;
    }else{
        return 0;
    }
}

sub BETWEEN{
    my ($s , $min , $max) = @_;
    if($s >= $min and $s <= $max){
        return 1;
    }else{
        return 0;
    }
}

sub URL{
    my ($s) = @_;
    return 1 unless $s;
    $s =~ m/^http:\/\/|^https:\/\//; 
}

1;
__END__

=head1 NAME

FormValidator::Simple::Struct::Regex - Plugin for FormValidator::Simple::Struct

=head1 VERSION

This document describes FormValidator::Simple::Struct::Regex version 0.18.

=head1 SYNOPSIS

 use FormValidator::Simple::Struct;
 $class = FormValidator::Simple::Struct->new;
 $class->load_plugin('FormValidator::Simple::Struct::Regex');

=head1 DESCRIPTION

This module provides some validate methods based on regex
 
 use Test::More;
 ok $class->NOT_BLANK('value');
 ng $class->NOT_BLANK('');

=head1 INTERFACE

=head2 Functions 

=head3 INT

 # allow integer ; 10 , 0 , -10
 ok $v->check(
    {key =>  "1" },
    {key => "INT"});

=head3 STRING

 # allow all Strings
 ok $v->check(
    ["111" , "abcde"],
    ["STRING"]);

=head3 ASCII

 # allow Arabic number and alphabet and ascii symbols
 ok $v->check(
    ["111" , 'abcde!"#$%%()'],
    ["ASCII"]);
 
 # not allow multi bytes characters
 ng $v->check(
    [Non-ASCII character],
    ["ASCII"]);

=head3 DECIMAL

 # allow integer and decimals ; 10 1,0 , 0 , -10 , -1.0
 ok $v->check(
    ["111" , "11.1" , "-11" , '0' , '-1.15'],
    ["DECIMAL"]);

=head3 URL

 # allow ^http|^https
 ok $v->check(
    ["http://google.com" , 'https://www.google.com/'],
    ["URL"]);

 ng $v->check(
    ["git://google.com" , 'smb://www.google.com/'],
    ["URL"]);

=head3 EMAIL

 this is base on Email::Valid;

=head3 DATETIME

 # The following examples are followed. 
 ok $v->check([
     '%Y-%m-%d %H:%M:%S',
     '%Y/%m/%d %H:%M:%S',
     '%Y-%m-%d %H-%M-%S',
     '%Y/%m/%d %H-%M-%S',],
 ['DATETIME']);

=head3 DATE

 # The following examples are followed. 
 ok $v->check([
    '%Y-%m-%d',
    '%Y/%m/%d'],
 ['DATE']);

=head3 TIME

 # The following examples are followed. 
 ok $v->check([
    '%H-%M-%S',
    '%H-%M-%S'],
 ['TIME']);

=head3 LENGTH

 # check value length
 $rule = ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 8]];
 ok $v->check(['a'] , $rule);
 ng $v->check(['abcdefghi'] , $rule);

 $rule = ["ASCII","NOT_BLANK" , ['LENGTH' , 4]];
 ng $v->check(['abc'] , $rule) # false 
 ok $v->check(['abcd'] , $rule) # true
 ng $v->check(['abcde'] , $rule) # false 

=head3 BETWEEN

 # check value 
 $rule = ["INT",['BETWEEN' , 1 , 8]];
 ok $v->check([1] , $rule) # true
 ng $v->check([3.1] , $rule) # false not INT
 ok $v->check([5] , $rule) # true
 ng $v->check([7.9] , $rule) # false not INT 
 ok $v->check([8] , $rule) # true
 ng $v->check([9] , $rule) # false, input is over 8
 ng $v->check([0] , $rule) # false, input is under 1

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

S2 E<lt>s2otsa59@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, S2. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

