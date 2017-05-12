# NAME

For::Else - Enable else blocks with foreach blocks

# SYNOPSIS

    use For::Else;
    
    foreach my $item ( @items ) {
      do_something( $item );
    }
    else {
      die 'no items';
    }

# DESCRIPTION

We iterate over a list like this:

    foreach my $item ( @items ) {
      do_something( $item );
    }

However I find myself needing to accommodate for the exceptional case when the
list is empty:

    if ( @items ) {
      foreach my $item ( @items ) {
        do_something( $item );
      }
    }
    else {
      die 'no items';
    }

Since we don't enter the *foreach* block when there are no items, I find the
*if* to be rather redundant. Wouldn't it be nice to get rid of it? Well now
you can :)

    use For::Else;
    
    foreach my $item ( @items ) {
      do_something( $item );
    }
    else {
      die 'no items';
    }

# SEE ALSO

[Fur::Elise](http://www.youtube.com/results?search_query=fur+elise) by [Ludwig van Beethoven](http://en.wikipedia.org/wiki/Ludwig_van_Beethoven)

The latest version can be found at:

&nbsp;&nbsp;&nbsp;&nbsp;[https://github.com/alfie/For-Else](https://github.com/alfie/For-Else)

Watch the repository and keep up with the latest changes:

&nbsp;&nbsp;&nbsp;&nbsp;[https://github.com/alfie/For-Else/subscription](https://github.com/alfie/For-Else/subscription)

# SUPPORT

Please report any bugs or feature requests at:

&nbsp;&nbsp;&nbsp;&nbsp;[https://github.com/alfie/For-Else/issues](https://github.com/alfie/For-Else/issues)

Feel free to fork the repository and submit pull requests :)

# INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

# DEPENDENCIES

* Filter::Simple

# AUTHOR

[Alfie John](https://github.com/alfie) &lt;[alfiej@opera.com](mailto:alfiej@opera.com)&gt;

# WARRANTY

IT COMES WITHOUT WARRANTY OF ANY KIND.

# COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
