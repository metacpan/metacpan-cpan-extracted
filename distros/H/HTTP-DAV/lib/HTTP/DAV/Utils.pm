package HTTP::DAV::Utils;

use strict;
use vars qw($VERSION);

$VERSION = '0.11';

###########################################################################
# Borrowed from Lincoln Stein's CGI.pm
# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearangement if:
# 1. The first parameter begins with a -
# 2. The use_named_parameters() method returns true
sub rearrange {
    my($order,@param) = @_;
    return () unless @param;

    # IF the user has passed a hashref instead of a hash then flatten it out.
    if (ref($param[0]) eq 'HASH') {
        @param = %{$param[0]};
    } else {
        # If the user has specified that they will be explicitly 
        # using named_parameters (by setting &use_named_parameters(1))
        # or the first parameter starts with a -, then continue.
        # Otherwise just return the parameters as they were given to us.
        return @param
            unless (defined($param[0]) && substr($param[0],0,1) eq '-')
                || &use_named_parameters();
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
        foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{$_} = $i; }
        $i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
        my $key = uc(shift(@param));
        $key =~ s/^\-//;
        if (exists $pos{$key}) {
            $result[$pos{$key}] = shift(@param);
        } else {
            $leftover{$key} = shift(@param);
        }
    }

    push (@result,&make_attributes(\%leftover)) if %leftover;
    @result;
}

#### Method: use_named_parameters
# Borrowed from Lincoln Stein's CGI.pm
# Force DAV.pm to use named parameter-style method calls
# rather than positional parameters.  The same effect
# will happen automatically if the first parameter
# begins with a -.
my $named=0;
sub use_named_parameters {
    my($use_named) = shift;
    return $named unless defined ($use_named);

    # stupidity to avoid annoying warnings
    return $named = $use_named;
}

# Borrowed from Lincoln Stein's CGI.pm
sub make_attributes {
    my($attr) = @_;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my(@att);
    foreach (keys %{$attr}) {
        my($key) = $_;
        $key=~s/^\-//;     # get rid of initial - if present
        $key=~tr/a-z_/A-Z-/; # parameters are upper case, use dashes
        push(@att,defined($attr->{$_}) ? qq/$key="$attr->{$_}"/ : qq/$key/);
    }
    return @att;
}

###########################################################################
sub bad {
   my($str) = @_;
   print STDERR "Error: $str\n";
   exit;
}

sub bad_node {
   my($node,$str) = @_;
   print STDERR "XML error in " . $node->getNodeName . ": $str";
   print STDERR "\n";
   print STDERR "DUMP:\n";
   print STDERR $node->toString if $node;
   exit;
}

###########################################################################
# This method searches for any text-based data in the children of 
# the node supplied. It will croak if the node has anything other 
# than text values (such as Elements or Comments).
sub get_only_cdata {
   my($node) = @_;
   my $return_cdata = "";
   my $nodes = $node->getChildNodes();
   my $n = $nodes->getLength;
   for (my $i = 0; $i < $n; $i++) {
      my $node = $nodes->item($i);   
      if ( $node->getNodeTypeName eq "TEXT_NODE" ) {
         $return_cdata .= $node->getNodeValue;
      } else {
         #bad_node($node, "node has non TEXT children");
      }
   }

   return $return_cdata;
}


# This is a sibling to the XML::DOM's getElementsByTagName().
# The main difference here is that it ignores the namespace 
# component of the element. This was done because it 
# Takes a node and returns a list of nodes.
# Note that the real getElementsByTagName allows you to 
# specify recurse or not. This routine doesn't allow recurse.
sub get_elements_by_tag_name {
   my ($node, $elemname ) = @_;

   return unless $node;

   my @return_nodes;

   # This is gruesome. Because we don't yet support namespaces, it 
   # just lops off the first half of the Element name
   $elemname =~ s/.*?:(.*)$/$1/g;

   my $nodelist = $node->getChildNodes();
   my $length = $nodelist->getLength();
   for ( my $i=0; $i < $length; $i++ ) {
      my $node = $nodelist->item($i);
      # Debian change?
      if ( $node->getNodeName() =~ /(?:^|:)$elemname$/ ) {
         push(@return_nodes,$node);
      }
   }

   return @return_nodes;
}

sub get_only_element {
   my($node,$elemname) = @_;

   return unless $node;

   # Find the one child element of a specific name
   if ( $elemname ) {

      # This is gruesome. Because we don't yet support namespaces, it 
      # just lops off the first half of the Element name.
      $elemname =~ s/.*?:(.*)$/$1/g;

      #my $nodes = $node->getElementsByTagName($elemname,0);
      my $nodelist = $node->getChildNodes();
      my $length = $nodelist->getLength();
      for ( my $i=0; $i < $length; $i++ ) {
         my $node = $nodelist->item($i);
         return $node if $node->getNodeName() =~ /$elemname/;
      }

#      if ( $nodes->getLength > 1 ) {
#         bad_node($node, "Too many \"$elemname\" in node"); 
#      } elsif ( $nodes->getLength < 1 ) {
#         return;
#         #bad_node($node, "No node found matching \"$elemname\" in node");
#      }
#      return $nodes->item(0);

   # Just get the first child element. 
   } else {
      my $nodelist = $node->getChildNodes();
      my $length = $nodelist->getLength();
      for ( my $i=0; $i < $length; $i++ ) {
         my $node = $nodelist->item($i);
         if ($node->getNodeTypeName eq "ELEMENT_NODE" ) {
            return $nodelist->item($i);
         }
      }
   }
}

###########################################################################
sub XML_remove_namespace {
   #print "XML: $_[0] -> ";
   $_[0] =~ s/.*?:(.*)/$1/g;
   #$_[0] =~ s/(.*?)\s.*/$1/g;
   #print "$_[0]\n";
   return $_[0];
}

###########################################################################
sub make_uri {
    my $uri = shift;
    if (ref($uri) =~ /URI/) { 
        $uri = $uri->as_string;
    }
    # Remove double slashes from the url
    $uri = URI->new($uri);
    my $path = $uri->path;
    $path =~ s{//}{/}g;
    #print "make_uri: $uri->$path\n";
    $uri->path($path);
    #print "make_uri: $uri\n";
    return $uri;
}

sub make_trail_slash {
    my ($uri) = @_;
    $uri =~ s{/*$}{}g;
    $uri .= '/';
    return $uri;
}

sub compare_uris {
    my ($uri1,$uri2) = @_;

    for ($uri1, $uri2) {
        $_ = make_uri($_);
        s{/$}{};
        s{(%[0-9a-fA-F][0-9a-fA-F])}{lc $1}eg;
	}

    return $uri1 eq $uri2;
}

# This subroutine takes a URI and gets the last portion 
# of it: the filename.
# e.g. /dir1/dir2/file.txt => file.txt
#      /dir1/dir2/         => dir2
#      /                   => undef
sub get_leafname {
   my($url) = shift;
   my $leaf;
   ($url,$leaf) = &split_leaf($url);
   return $leaf;
}

# This subroutine takes a URI and splits the leaf from the path.
# It returns both.
# of it: the filename.
# e.g. /dir1/dir2/file.txt => file.txt
#      /dir1/dir2/         => dir2
#      /                   => undef
sub split_leaf {
   my($url) = shift;
   $url =~ s#[\/\\]$##; #Remove trailing slashes.
   $url = HTTP::DAV::Utils::make_uri($url);

   # Remove the leaf from the path.
   my $path = $url->path_query();
   my @path = split(/[\/\\]+/,$path);
   my $leaf = pop @path || "";
   $path = join('/',@path);

   #Now put the path back into the URL.
   $url->path_query($path);

   return ($url,$leaf);
}

# Turns a file-oriented glob
# into a regular expression.
# BTW, I recommend you eval any regex command you use on 
# this outputted  regex value.
# If somebody types uses an incorrect glob and you try to /$regex/ it 
# then perl will bomb with a fatal regex error.
# For instance, /file[ab.txt/ would bomb.
sub glob2regex {
   my($f) = @_;
   # Turn the leafname glob into a regex.
   # Substitute \ for \\
   # Substitute . for \.
   # Substitute * for .*
   # Substitute ? for .
   # No need to substitute [...]
   $f =~ s/\\/\\\\/g;
   $f =~ s/\./\\./g;
   $f =~ s/\*/.*/g;
   $f =~ s/\?/./g;
   print "Glob regex becomes $f\n" if $HTTP::DAV::DEBUG>1;
   return $f;
}

1;
