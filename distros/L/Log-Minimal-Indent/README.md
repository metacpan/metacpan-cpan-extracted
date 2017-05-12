[![Build Status](https://travis-ci.org/Maki-Daisuke/p5-Log-Minimal-Indent.png?branch=master)](https://travis-ci.org/Maki-Daisuke/p5-Log-Minimal-Indent)
# NAME

Log::Minimal::Indent - Log::Minimal extension to support indentation

# SYNOPSIS

    use Log::Minimal;
    use Log::Minimal::Indent;
    

    infof("Level zero");
    {
        indent_log_scope("foo");  # Indent forward one level in this block.
        warnf "Something to warn";
        {
            indent_log_scope("bar", "MUTE");  # You can mute enter/exit message.
            critf "Something critical happens!";
        }
        infof "Indent back here";
    }
    infof("Level zero again");
    

    # The above code prints like this:
    # 
    # 2013-09-23T11:39:19 [INFO] Level zero
    # 2013-09-23T11:39:19 [INFO] <Entering foo>
    # 2013-09-23T11:39:19   [WARN] Something to warn
    # 2013-09-23T11:39:19     [CRITICAL] Something critical happens!
    # 2013-09-23T11:39:19   [INFO] Indent back here
    # 2013-09-23T11:39:19 [INFO] <Exited foo>
    # 2013-09-23T11:39:19 [INFO] Level zero again
    

    # You can write the same program like this:
    use Log::Minimal::Indent;  # Actually, you don't need to use Log::Minimal,
                               # which automatically uses it for you.
    

    infof("Level zero");
    {
        my $g = indent_log_guard("foo");  # Indent one lovel as long as Guard object is alive.
        warnf "Something to warn";
        {
            my $h = indent_log_guard("bar", "MUTE");  # You can mute enter/exit message.
            critf "Something critical happens!";
        }
        infof "Indent back here";
    }
    infof("Level zero again");

# DESCRIPTION

This module allows you to make indentation in logs output by Log::Minimal.

# EXPORT FUNCTIONS

## indent\_log\_scope($tag, $type)

## indent\_log\_guard($tag, $type)

    indent_log_scope("tag", "INFO")
    my $guard = indent_log_guard("tag", "INFO")

`indent_log_scope` indents log messages forward within a scope (block, subroutine, eval... etc),
then, indent back automatically when the execution exits from the scope.

`indent_log_guard` works similarly, but it keeps forward-indent by the last reference to its
return-value ([Guard](http://search.cpan.org/perldoc?Guard) object) is gone.

- `$tag:Str`

    This is a kind of comment meaning what does this block is doing.
    This string is used in the log message output by the functions like:

        [INFO] Entering <tag>
        ...
        [INFO] Exited <tag>

- `$type:Str` (default: "INFO")

    Specifies which log level is used to output log message.
    This argumment should be one of "DEBUG", "INFO", "WARN", "CRITICAL",
    "MUTE" and "ERROR". The default value is "INFO".
    You can disable log message by specifying "MUTE".

        indent_log_scope('bar', "MUTE");  # Does not output log messages.

# Manual Indentation

## Log::Minimal::Indent->forward($tag, $type)

## Log::Minimal::Indent->back($tag, $type)

If you really want to manage indentation by yourself, you can use these method to indent forward or back.

    Log::Minimal::Indent->forward("hoge");
        ...
            Log::Minimal::Indent->forward("fuga");
            ...
            Log::Minimal::Indent->back("fuga");
        ...
    Log::Minimal::Indent->back("hoge");

# GLOBAL VARIABLE

## $Log::Minimal::Indent::PADDING

Specifys prefixed-string to indent. Default to "  " (two white-spaces).

# CUSTOMIZATION OF Log::Minimal

Log::Minimal::Indent modifies and overwrites a behaviour of Log::Minimal.
If you customize Log::Minimal with using $Log::Minimal::PRINT or $Log::Minimal::DIE,
read this section carefully.

Log::Minimal::Indent extends the parameter of $PRINT and $DIE as follows:

    $PRINT->($time, $type, $message, $trace,$raw_message, $indent_level);

They receive one additional parameter `$indent_level`. This integer value shows
how deep indent level Log::Minimal::Indent is currently at. The other parameters
are passed as-is, including $raw\_message. That is, you need to handle indentation
by yourself according to $indent\_level when you use your own `$PRINT` or `$DIE`.

Log::Minimal::Indent overwrites `$PRINT` and `$DIE` the first time it is `use`d 
or `require`d to handle indentation.
Thus, you must `use` this module before overriting `$PRINT` or `$DIE`.

# LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke (yet another) Maki <maki.daisuke AT gmail.com>
