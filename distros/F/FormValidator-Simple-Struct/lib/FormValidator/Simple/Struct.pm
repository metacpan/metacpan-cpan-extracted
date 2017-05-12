package FormValidator::Simple::Struct;
use 5.008_001;
use strict;
use warnings;
use FormValidator::Simple::Struct::Regex;
use FormValidator::Simple::Struct::CharTypes;
use Carp;
use Test::More;
use Data::Dumper;
use Class::Load;

our $VERSION = '0.18';

# static values
sub HASHREF {'excepted hash ref'};
sub HASHVALUE {'excepted hash value'};
sub ARRAYREF {'excepted array ref'};
sub NO_SUCH_CHAR_TYPE {'was not declare ' . $_->[0]};
sub REF {'excepted ref'};
sub INVALID{'excepted ' . $_[0]};

sub LENGTH_ERROR{'LENGTH IS WRONG'};
sub DIGIT_LENGTH_ERROR{'DIGIT_LENGTH IS WRONG'};
sub BETWEEN_ERROR{'BETWEEN IS WRONG'};
sub CHARS_ERROR{'NOT ALLOWED CHAR EXIST'};

sub new{
    my $class = bless {} , $_[0];
    $class->load_plugin('FormValidator::Simple::Struct::CharTypes');
    $class->load_plugin('FormValidator::Simple::Struct::Regex');
    $class->load_plugin('FormValidator::Simple::Struct::AllowCharacter');
    $class;
}

sub load_plugin {
    my ($class, $pkg, $opt) = @_;
    Class::Load::load_class($pkg);
    no strict 'refs';
    for my $meth ( @{"${pkg}::EXPORT"} ) {
        my $dest_meth =
          ( $opt->{alias} && $opt->{alias}->{$meth} )
          ? $opt->{alias}->{$meth}
          : $meth;
        *{"${class}::${dest_meth}"} = *{"${pkg}::$meth"};
    }
}

sub check{
    my($self , $param , $rule) = @_;

    $self->{error} = 1;
    croak('set params') if !$param or !$rule;

    $self->{error} = 0;
    $self->{error_object} = [];
    $self->_check($param , $param , $rule , '$param');
    
    !$self->{error};
}

sub _check{
    my($self , $param , $parent_params , $rule , $position , $name) = @_;

    if(ref $param eq 'Hash::MultiValue'){
        $param = $param->as_hashref;
    }

    if(ref $param){
        my $ref = ref $rule;
        if(ref $param ne $ref){
            if($ref eq 'ARRAY'){
                $self->_set_error(HASHREF, $position , $name);
            }elsif($ref eq 'HASH'){
                $self->_set_error(ARRAYREF, $position , $name);
            }else{
                croak('declareother types : HASH or ARRAY');
            }
        }else{
            if($ref eq 'HASH'){
                for(keys %$rule){
                    unless(exists $param->{$_}){
                        if(ref $rule->{$_} eq 'ARRAY' and ref $rule->{$_}[0] eq 'ARRAY'){
                            $self->_set_error(ARRAYREF, $position, $_ ,'NOT_BLANK');
                        }else{
                            if(_instr($rule->{$_},'NOT_BLANK')){
                                $self->_set_error(HASHVALUE, $position, $_ ,'NOT_BLANK');
                            }
                        }
                    }else{
                        $self->_check($param->{$_} , $param , $rule->{$_} , $position . "->{$_}" , $_);
                    }
                }
            }elsif($ref eq 'ARRAY'){
                if(@$rule != 1 && @$rule != @$param){
                    $self->_set_error(
                        '$rule\'s length differs from $param\'s length',
                        $position,
                        $name , 'ARRAY_LENGTH');
                    return;
                }
                for(0..$#{$param}){
                    if(defined $rule->[$_]){
                        $self->_check($param->[$_] || "" , $param , $rule->[$_] , $position . "->[$_]" , $name);
                    }else{
                        $self->_check($param->[$_] || "" , $param , $rule->[0] , $position . "->[$_]" , $name);
                    }
                }
            }else{
                croak($ref . ':declare other types : HASH or ARRAY');
            }
        }
    }else{
        if(ref $rule eq 'HASH'){
            $self->_set_error(HASHREF, $position , $name , 'HASH');
            return;
        }elsif(ref $rule eq 'ARRAY'){
            if($rule->[0] eq 'CHARTYPE'){
                my (undef , @allow_chars) = @$rule;
                
                my $range = '';
                for my $chars_name(@allow_chars){
                    my $code = $self->can("CHARTYPE::$chars_name");
                    die NO_SUCH_CHAR_TYPE($chars_name) unless $code;
                    $range .= $code->();
                }
                
                if ($param =~ m/[$range]/){
                    my $message = CHARS_ERROR;
                    $self->_set_error($message, $position , $name , '');
                }
            }elsif($rule->[0] eq 'ALLOWCHARACTER'){
                my (undef , @allow_chars) = @$rule;
                for(@allow_chars){
                    $param =~ s/$param/$_/g;
                }
            }else{
                for(@$rule){
                    if (ref $_ eq 'ARRAY'){
                        my ($type , $min , $max) = @$_;
                        if($min && $min !~ /^\d+\.\d+$|^\d+$/){
                            $min = $parent_params->{$min}
                        }
                        if($max && $max !~ /^\d+\.\d+$|^\d+$/){
                            $max = $parent_params->{$max}
                        }

                        $max = $min unless defined $max;

                        if($type eq 'LENGTH' or $type eq 'BETWEEN'){
                            if($max < $min ){
                                ($max , $min) = ($min , $max);
                            }
                            no strict;

                            my $code = $self->can($type);
                            die NO_SUCH_CHAR_TYPE($type) unless $code;
                            unless($code->($param,$min,$max)){
                                my $message;
                                if($type eq 'LENGTH'){
                                    $message = LENGTH_ERROR;
                                }else{
                                    $message = BETWEEN_ERROR;
                                }
                                $self->_set_error($message, $position , $name , $type, $min , $max);
                            }
                        }elsif($type eq 'DIGIT_LENGTH'){
                            no strict;

                            my $code = $self->can($type);
                            die NO_SUCH_CHAR_TYPE($type) unless $code;
                            unless($code->($param,$min,$max)){
                                my $message = DIGIT_LENGTH_ERROR;
                                $self->_set_error($message, $position , $name , $type, $min , $max);
                            }
                        }elsif($type eq 'CHARTYPE'){
                            my (undef , @allow_chars) = @$_;
                            
                            my $range = '';
                            for my $chars_name(@allow_chars){
                                my $code = $self->can("CHARTYPE::$chars_name");
                                die NO_SUCH_CHAR_TYPE($chars_name) unless $code;
                                $range .= $code->();
                            }
                            
                            if ($param =~ m/[$range]/){
                                my $message = CHARS_ERROR;
                                $self->_set_error($message, $position , $name , '');
                            }
                        }elsif($type eq 'ALLOWCHARACTER'){
                            my (undef , @allow_chars) = @$_;
                            for my $allow_char_method(@allow_chars){
                                my $code = $self->can("ALLOWCHARACTER::$allow_char_method");
                                my $replace_string = $code->();
                                $param =~ s/$replace_string//g;
                            }
                        }else{
                            croak "Not declare type:" . $type;
                        }
                    }elsif (ref $_){
                        $self->_set_error(HASHREF, $position , $name ,'ARRAY');
                        return;
                    }else{
                        my $code = $self->can($_);
                        die NO_SUCH_CHAR_TYPE($_) unless $code;
                        unless($code->($param)){
                            $self->_set_error(INVALID($_), $position , $name , $_);
                        }
                    }
                }
            }
        }else{
            my $code = $self->can($rule);
            die NO_SUCH_CHAR_TYPE($rule) unless $code;
            unless($code->($param)){
                $self->_set_error(INVALID($rule), $position , $param , $rule);
            }
        }
    }
}

sub has_error{
    $_[0]->{error};
}

sub _set_error{
    my ($self,$message,$position,$param_name,$error,$min,$max) = @_;
    $self->{error} = 1;
    $self->{error_object} ||= [];
    push @{$self->{error_object}} , {
        message => $message ,position =>  $position , 
        param_name => $param_name , error => $error,
        min_value => $min , max_value => $max ,
    };
}

sub get_error{
    $_[0]->{error_object} ||= [];
}

sub _instr{
    my ($array , $word) = @_;
    for(@$array){
        if($_ eq $word){
            return 1;
        }
    }
    return 0;
}

1;
__END__

=head1 NAME

FormValidator::Simple::Struct - Validation module for nested array ,hash ,scalar  like FormValidator::Simple

=head1 VERSION

This document describes FormValidator::Simple::Struct version 0.18.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

    You can check some value types in Scalar , Arrayref , Hashref.

=head1 Functions

=head2 check

  $v = FormValidator::Simple::Struct->new();
  $v->check(111 , "INT"); # return true
  $v->check(111 , "STRING"); # return false and $v->has_error is true 
  $v->check([111 , 1222, 333] , ["INT"]);# return true
  $v->check({ key  => 'value'},{key=> "ASCII"});# return true
  $v->check([{id => 111,id2=> 22.2 },{id=> 1222 , id2=> 1.11},{id=> 333 , id2=> 44.44}] , [{id =>"INT",id2 => "DECIMAL"}]);# return true

=head2 has_error

  $v->check(
    {key =>  "abcdefghijklmnop" },
    {key => ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 15]]});
  if($v->has_error){
      # error handling routine
  }

=head2 get_error

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

=head2 INT

 # allow integer ; 10 , 0 , -10
 ok $v->check(
    {key =>  "1" },
    {key => "INT"});

=head2 STRING

 # allow all Strings
 ok $v->check(
    ["111" , "abcde"],
    ["STRING"]);

=head2 ASCII

 # allow Arabic number and alphabet and ascii symbols
 ok $v->check(
    ["111" , 'abcde!"#$%%()'],
    ["ASCII"]);
 
 # not allow multi bytes characters
 ng $v->check(
    [Non-ASCII character],
    ["ASCII"]);

=head2 DECIMAL

 # allow integer and decimals ; 10 1,0 , 0 , -10 , -1.0
 ok $v->check(
    ["111" , "11.1" , "-11" , '0' , '-1.15'],
    ["DECIMAL"]);

=head2 URL

 # allow ^http|^https
 ok $v->check(
    ["http://google.com" , 'https://www.google.com/'],
    ["URL"]);

 ng $v->check(
    ["git://google.com" , 'smb://www.google.com/'],
    ["URL"]);

=head2 EMAIL

 this is base on Email::Valid;

=head2 DATETIME

 # The following examples are followed. 
 ok $v->check([
     '%Y-%m-%d %H:%M:%S',
     '%Y/%m/%d %H:%M:%S',
     '%Y-%m-%d %H-%M-%S',
     '%Y/%m/%d %H-%M-%S',],
 ['DATETIME']);

=head2 DATE

 # The following examples are followed. 
 ok $v->check([
    '%Y-%m-%d',
    '%Y/%m/%d'],
 ['DATE']);

=head2 TIME

 # The following examples are followed. 
 ok $v->check([
    '%H-%M-%S',
    '%H-%M-%S'],
 ['TIME']);

=head2 LENGTH

 # check value length
 $rule = ["ASCII","NOT_BLANK" , ['LENGTH' , 1 , 8]];
 ok $v->check(['a'] , $rule);
 ng $v->check(['abcdefghi'] , $rule);

 $rule = ["ASCII","NOT_BLANK" , ['LENGTH' , 4]];
 ng $v->check(['abc'] , $rule) # false 
 ok $v->check(['abcd'] , $rule) # true
 ng $v->check(['abcde'] , $rule) # false 

=head2 BETWEEN

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
