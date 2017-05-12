# NAME

Devel::Comment::Output - Comment program output to your script after execution

# SYNOPSIS

Write your script:

    use Devel::Comment::Output;
    use Data::Dumper;

    print 1 + 2;
    print Dumper { a => 1 };

after running, comments are added to the script like:

    # use Devel::Comment::Output;
    use Data::Dumper;

    print 1 + 2; # => 3;
    print Dumper { a => 1 };
    # $VAR1 = {
    #           'a' => 1
    #         };

# DESCRIPTION

Devel::Comment::Output captures script outputs and
embeds the outputs to the script.

# OPTIONS

    use Devel::Comment::Output;

is equivalent to below:

    use Devel::Comment::Output (
        handle => \*STDOUT, # Handle to capture
        file => __FILE__,   # File to rewrite
        inline => 1,        # Allow inline comment
        prefix => '=> '     # Inline comment prefix
    );

# AUTHOR

motemen <motemen@gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.