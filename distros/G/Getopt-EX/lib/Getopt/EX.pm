package Getopt::EX;
use 5.014;
use version; our $VERSION = version->declare("v1.23.0");

1;

=head1 NAME

Getopt::EX - Getopt Extender


=head1 VERSION

Version v1.23.0


=head1 DESCRIPTION

L<Getopt::EX> extends the basic function of L<Getopt> family to
support user-definable option aliases, and dynamic module which works
together with the script through option interface.

=head1 INTERFACES

There are two major interfaces to use L<Getopt::EX> modules.

Easy one is L<Getopt::Long> compatible module, L<Getopt::EX::Long>.
You can simply replace module declaration and get the benefit of this
module to some extent.  It allows user to make start up I<rc> file in
their home directory, which provide user-defined option aliases.

Use L<Getopt::EX::Loader> to get full capabilities.  Then the user of
your script can make their own extension module which work together
with original command through command option interface.

Another module L<Getopt::EX::Colormap> is made to produce colored text
on ANSI terminal, and to provide easy way to maintain labeled colormap
table and option handling.  It can be used just like
L<Term::ANSIColor> but you'd better use standard module in that case.

=head2 L<Getopt::EX::Long>

This is the easiest way to get started with L<Getopt::EX>.  This
module is almost compatible with L<Getopt::Long> and replaceable.

In addition, if the command name is I<example>,

    ~/.examplerc

file is loaded by default.  In this rc file, user can define their own
option with macro processing.  This is useful when the command takes
complicated arguments.  User can also define default option which is
used always.  For example,

    option default -n

gives option I<-n> always when the script executed.  See
L<Getopt::EX::Module> document what you can do in this file.

If the rc file includes a section start with C<__PERL__>, it is
evaluated as a perl program.  User can define any kind of functions
there, which can be invoked from command line option if the script is
aware of them.  At this time, module object is assigned to variable
C<$MODULE>, and you can access module API through it.

Also, special command option preceded by B<-M> is taken and
corresponding perl module is loaded.  For example,

    % example -Mfoo

will load C<App::example::foo> module.

This module is normal perl module, so user can write anything they
want.  If the module option come with initial function call, it is
called at the beginning of command execution.  Suppose that the module
I<foo> is specified like this:

    % example -Mfoo::bar(buz=100) ...

Then, after the module B<foo> is loaded, function I<bar> is called
with the parameter I<buz> with value 100.

If the module includes C<__DATA__> section, it is interpreted just
same as rc file.  So you can define arbitrary option there.  Combined
with startup function call described above, it is possible to control
module behavior by user defined option.

=head2 L<Getopt::EX::Loader>

This module provides more primitive access to the underlying modules.
You should create loader object first:

  use Getopt::EX::Loader;
  my $loader = Getopt::EX::Loader->new(
      BASECLASS => 'App::example',
      );

Then load rc file:

  $loader->load_file("$ENV{HOME}/.examplerc");

And process command line options:

  $loader->deal_with(\@ARGV);

Finally gives built-in function declared in dynamically loaded modules
to option parser.

  my $parser = Getopt::Long::Parser->new;
  $parser->getoptions( ... , $loader->builtins )

Actually, this is what L<Getopt::EX::Long> module is doing
internally.

=head2 L<Getopt::EX::Func>

To make your script to communicate with user-defined subroutines, use
L<Getopt::EX::Func> module, which provide C<parse_func> interface.  If
your script has B<--begin> option which tells the script to call
specific function at the beginning of execution.  Write something
like:

    use Getopt::EX::Func qw(parse_func);
    GetOptions("begin:s" => $opt_begin);
    my $func = parse_func($opt_begin);
    $func->call;

Then the script can be invoked like this:

    % example -Mfoo --begin 'repeat(debug,msg=hello,count=2)'

See L<Getopt::EX::Func> for more detail.

=head2 L<Getopt::EX::Colormap>

This module is not so tightly coupled with other modules in
L<Getopt::EX>.  It provides concise way to specify ANSI terminal 256
colors with various effects, and produce terminal sequences by color
specification or label parameter.

You can use this with normal L<Getopt::Long>:

    my @opt_colormap;
    use Getopt::Long;
    GetOptions("colormap|cm=s" => \@opt_colormap);
    
    my %colormap = ( # default color map
        FILE => 'R',
        LINE => 'G',
        TEXT => 'B',
        );
    my @colors;
    
    require Getopt::EX::Colormap;
    my $handler = Getopt::EX::Colormap->new(
        HASH => \%colormap,
        LIST => \@colors,
        );
    
    $handler->load_params(@opt_colormap);

and then get colored string as follows.

    print $handler->color("FILE", "FILE in Red\n");
    print $handler->color("LINE", "LINE in Blue\n");
    print $handler->color("TEXT", "TEXT in Green\n");

In this example, user can change these colors from command line option
like this:

    % example --colormap FILE=C,LINE=M,TEXT=Y

or call arbitrary perl function like:

    % example --colormap FILE='sub{uc}'

Above example produces uppercase version of provided string instead of
ANSI color sequence.

If you only use coloring function, it's more simple:

    require Getopt::EX::Colormap;
    my $handler = Getopt::EX::Colormap->new;

    print $handler->color("R", "FILE in Red\n");
    print $handler->color("G", "LINE in Blue\n");
    print $handler->color("B", "TEXT in Green\n");

or even simpler non-oo interface:

    use Getopt::EX::Colormap qw(colorize);

    print colorize("R", "FILE in Red\n");
    print colorize("G", "LINE in Blue\n");
    print colorize("B", "TEXT in Green\n");

=head2 L<Getopt::EX::LabeledParam>

This is super-class of L<Getopt::EX::Colormap>.  L<Getopt::Long>
support parameter handling within hash,

    my %defines;
    GetOptions ("define=s" => \%defines);

and the parameter can be given in C<key=value> format.

    --define os=linux --define vendor=redhat

Using L<Getopt::EX::LabeledParam>, this can be written as:

    my @defines;
    my %defines;
    GetOptions ("defines=s" => \@defines);
    Getopt::EX::LabeledParam
        ->new(HASH => \%defines)
        ->load_params (@defines);

and the parameter can be given mixed together.

    --define os=linux,vendor=redhat

=head2 L<Getopt::EX::Numbers>

Parse number parameter description and produces number range list or
number sequence.  Number format is composed by four elements: C<start>,
C<end>, C<step> and C<length>, like this:

    1		1
    1:3		1,2,3
    1:20:5	1,     6,     11,       16
    1:20:5:3	1,2,3, 6,7,8, 11,12,13, 16,17,18

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2015-2021 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  Getopt colormap perl foo bar buz colorize BASECLASS
#  LocalWords:  rc examplerc ENV ARGV getoptions builtins func
#  LocalWords:  GetOptions
