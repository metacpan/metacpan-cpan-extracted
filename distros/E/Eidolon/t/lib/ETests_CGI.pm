package ETests_CGI;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/lib/ETests_CGI.pm - tied STDIN class for CGI POST tests
#
# ==============================================================================

use warnings;
use strict;

our $post = "i=ve&got=a&poison=i&ve=got&a=remedy";
our $post_multipart = qq#--peoplecanfly\r\nContent-Disposition: form-data; #   .
                      qq#name="astral"\r\n\r\nprojection\r\n--peoplecanfly\r\n#.
                      qq#Content-Disposition: form-data; name="text"; filename#.
                      qq#="base_001.txt"\r\nContent-Type: text/plain\r\n\r\n#  .
                      qq#All your base are belong to us.\r\n--peoplecanfly--#  .
                      qq#\r\n#;

# ------------------------------------------------------------------------------
# TIEHANDLE($class, $start)
# handle initialization
# ------------------------------------------------------------------------------
sub TIEHANDLE 
{ 
    my ($class, $start) = @_;
    $start = 0;
    return bless \$start => $class; 
} 

# ------------------------------------------------------------------------------
# READLINE()
# read line
# ------------------------------------------------------------------------------
sub READLINE
{ 
    my ($self, @lines); 

    $self  = shift;
    @lines = split /\r\n/, $post_multipart;

    if ($$self < scalar @lines)
    {
        return $lines[$$self++]."\r\n";
    }

    return undef; 
} 

# ------------------------------------------------------------------------------
# READ($bufref, $len, $offset)
# read data
# ------------------------------------------------------------------------------
sub READ
{
    my ($self, $bufref, $len, $offset);

    $self = shift;
    $bufref = \$_[0];
    
    (undef, $len, $offset) = @_;

    if (!$$self && $len == length($post))
    {
        $$self = 1;
        $$bufref .= $post;
        return length($post);
    }

    return 0;
}

1;

