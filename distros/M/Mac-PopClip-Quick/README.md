# NAME

Mac::PopClip::Quick - quickly write PopClip extensions in Perl

# SYNOPSIS

First write a script:

    #!/usr/bin/perl

    use 5.012;
    use warnings;
    use autodie;

    use Mac::PopClip::Quick;
    use POSIX qw(strftime);

    open my $fh, ''>>:utf8', "$ENV{HOME}/Dropbox/runlog.txt";
    say $fh strftime("%FT%T",gmtime) . ' ' . popclip_text();

Then install it as a PopClip Extension

    bash$ INSTALL_POPCLIP_EXTENSION=1 ./runlog.pl

# DESCRIPTION

PopClip For Mac is a commercial OS X utility from Pilotmoon Software that
creates little popup menus when you highlight text.  Please see
[http://pilotmoon.com/popclip/](http://pilotmoon.com/popclip/) for more details.

This module make it easier to write PopClip extensions in Perl.  With this
module you can turn a simple Perl script into an installable extension with a
single command.

The resulting extension does not depend on the Mac::PopClip::Quick module, and
can be safely distributed to systems that do not have this module installed.

## Examples

In your script you should `use Mac::PopClip::Quick`.

    #!/usr/bin/perl

    use Mac::PopClip::Quick;
    system('say','The selected text is '.popclip_text());

From the command line you simply need to execute the script with the
`INSTALL_POPCLIP_EXTENSION` environment variable set to a true value.

    bash$ INSTALL_POPCLIP_EXTENSION=1 ./reverse.pl

You can also create an executable suitable for distribution using the

    bash$ CREATE_POPCLIP_EXTENSION=1 ./reverse.pl

Options can be set by passing them in the `use` statement:

    use Mac::PopQuick::Quick (
        extension_identifier => 'com.yourdomain.extensionname',
    );

They'll be passed through to the underlying [Mac::PopClip::Quick::Generator](https://metacpan.org/pod/Mac::PopClip::Quick::Generator)
class's constructor.

You can use `after_action` to control what your extension does with the
script output, for example pasting it:

    use Mac::PopQuick::Quick (
        extension_name => 'Reverse Text',
        after_action => 'paste-result',
    );
    print reverse popclip_text();

# Supported Options

## Core Options

### extension\_name

The name of the extension.  By default this is the name of the script, minus
any file extension (e.g. if your script if called `foo.pl` then the extension
will be called `foo` by default.)

### title

The title.  By default, the same as the `extension_name`.

### filename

The filename that the tarball will be created with.  Should end with
`.popclipextz` (though we don't force you to.)

By default a temporary filename is used if no value is provided.  If the
`CREATE_POPCLIP_EXTENSION` environment variable is set then this will be
printed out.

### extension\_identifier

A unique identifier for your extension.  This enables PopClip to identify
if an extension it's installing should install as a new extension or replace
an older version of the same extension.

By default this will generate something unique for you by using the unique ID of
your Mac and the extension name.  This is **not** suitable for distribution (if
you change hardware you won't be able to use it anymore) and you should set a
value for this attribute before distributing your extension.

## Options Controlling PopClip Behavior

### required\_software\_version

The required version of PopClip.  By default this is 701.

### regex

A string containing the regex that controls when the extension will be
triggered.  Note that this is not a Perl regex, but rather a string that PopClip
can execute as a PCRE.

By default this is undefined, meaning no regex is used.

### script\_interpreter

The program you want to use to execute your Perl script (it can be handy to set
this if you want to use a perl other than the system perl, e.g. a perl you
installed with perlbrew)

By default this is `/usr/bin/perl`, the system perl.

### blocked\_apps

Array of bundle identifier strings (e.g. `com.apple.TextEdit`) of applications
for which this extension's actions should not appear.

### required\_apps

Array of bundle identifier strings of applications (e.g. `com.apple.TextEdit`)
that this extension's actions will appear in.

# FUNCTIONS

Just the one:

## popclip\_text

Exported by default, this function simply returns the value of
`%ENV{POPCLIP_TEXT}` (but gives better error messages if you mistype it and
have use strict turned on.)

Since the Perl source code that is bundled in the generated extension is
modified so it no longer loads this module (so that if you distribute your
extension then your end users do not have to install this module) the code
for this function will be directly inserted into the modified source code.

This function is defined with an empty prototype, meaning you can call it
without having to use parentheses.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Fowler.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

# BUGS

Several features of PopClip aren't yet supported.

Installing this extension leaves a copy of it (unavoidably, because there's
no way to tell when PopClip is done with the file) in the temp directory.

If your code has Perl's subroutine signatures feature enabled at the time you
import this module then the modified code will not properly define the prototype
for the `popclip_text` function meaning you will be unable to call it without
parentheses.

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/2shortplanks/Mac-PopClip-Quick/issues](https://github.com/2shortplanks/Mac-PopClip-Quick/issues).

Patches welcome, ideally as a GitHub pull request for the GitHub repo at
[https://github.com/2shortplanks/Mac-PopClip-Quick](https://github.com/2shortplanks/Mac-PopClip-Quick).

# SEE ALSO

You can find more out about PopClip at [http://pilotmoon.com/popclip](http://pilotmoon.com/popclip).

[Mac::PopClip::Quick::Generator](https://metacpan.org/pod/Mac::PopClip::Quick::Generator) is the workhorse that actually builds the
PopClip extensions behind the scene.
