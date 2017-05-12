###########################################
# File::Comments -- 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments;
###########################################

use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(:all);
use File::Basename;
use Module::Pluggable
  require     => 1,
  #search_path => [qw(File::Comments::Plugin)],
  ;

our $VERSION = "0.08";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {

        cold_calls     => 1,
        default_plugin => undef,

        suffixes   => {},
        bases      => {},
        plugins    => [],
        %options,
    };

    bless $self, $class;

        # Init plugins
    $self->init();

    return $self;
}

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->{plugins} = [];

    for($self->plugins()) {
        DEBUG "Initializing plugin $_";
        my $plugin = $_->new(mothership => $self);
        push @{$self->{plugins}}, $plugin;
    }
}

###########################################
sub find_plugin {
###########################################
    my($self) = @_;

        # Is there a suffix handler defined?
    if(defined $self->{target}->{suffix} and
       exists $self->{suffixes}->{$self->{target}->{suffix}}) {

        DEBUG "Searching for plugin handling suffix $self->{target}->{suffix}";

        for my $plugin (@{$self->{suffixes}->{$self->{target}->{suffix}}}) {
            DEBUG "Checking if ", ref $plugin, 
                  " is applicable for suffix ",
                  "'$self->{target}->{suffix}'";
            if($plugin->applicable($self->{target})) {
                DEBUG ref($plugin), " accepted";
                return $plugin;
            } else {
                DEBUG ref($plugin), " rejected";
            }
        }
    }

        # Is there a base handler defined?
    if(defined $self->{target}->{file_base} and
       exists $self->{bases}->{$self->{target}->{file_base}}) {

        DEBUG "Searching for plugin handling base $self->{target}->{file_base}";

        for my $plugin (@{$self->{bases}->{$self->{target}->{file_base}}}) {
            DEBUG "Checking if ", ref $plugin, 
                  " is applicable for base ",
                  "'$self->{target}->{file_base}'";
            if($plugin->applicable($self->{target})) {
                DEBUG ref($plugin), " accepted";
                return $plugin;
            } else {
                DEBUG ref($plugin), " rejected";
            }
        }
    }

        # Hmm ... no volunteers yet.
    return undef unless $self->{cold_calls};

        # Go from door to door and check if some plugin wants to 
        # handle it. Set the 'cold_call' flag to let the plugin know
        # about our desparate move.
    for my $plugin (@{$self->{plugins}}) {
         DEBUG "Checking if ", ref $plugin, " is applicable for ",
               "file '$self->{target}->{path}' (cold call)";
        if($plugin->applicable($self->{target}, 1)) {
            DEBUG "Cold call accepted";
            return $plugin;
        } else {
            DEBUG "Cold call rejected";
        }
    }

    return undef;
}

###########################################
sub guess_type {
###########################################
    my($self, $target) = @_;

    if(ref $target) {
        $self->{target} = $target;
    } else {
        $self->{target} = File::Comments::Target->new(path => $target);
    }

    my $plugin = $self->find_plugin();

    if(! defined $plugin) {
        ERROR "No plugin found to handle $target";
        return undef;
    }

    return $plugin->type(); 
}

###########################################
sub comments {
###########################################
    my($self, $target) = @_;

    return  $_[0]->dispatch($target, "comments");
}

###########################################
sub stripped {
###########################################
    my($self, $target) = @_;

    return  $_[0]->dispatch($target, "stripped");
}

###########################################
sub dispatch {
###########################################
    my($self, $target, $function) = @_;

    if(ref $target) {
        $self->{target} = $target;
    } else {
        $self->{target} = File::Comments::Target->new(path => $target);
    }

    my $plugin = $self->find_plugin();

    if(! defined $plugin) {
        if($self->{default_plugin}) {
            $plugin = $self->{default_plugin};
        } else {
            ERROR "Type of $target couldn't be determined";
                # Just return and empty list
            return undef;
        }
    }

    DEBUG "Calling ", ref $plugin, 
          " to handle $self->{target}->{path}";

    return $plugin->$function($self->{target});
}

###########################################
sub register_suffix {
###########################################
    my($self, $suffix, $plugin_obj) = @_;

    DEBUG "Registering ", ref $plugin_obj, 
          " as a handler for suffix $suffix";

        # Could be more than one, line them up
    push @{$self->{suffixes}->{$suffix}}, $plugin_obj;
}

###########################################
sub suffix_registered {
###########################################
    my($self, $suffix) = @_;

    return exists $self->{suffixes}->{$suffix};
}

###########################################
sub register_base {
###########################################
    my($self, $base, $plugin_obj) = @_;

    DEBUG "Registering ", ref $plugin_obj, 
          " as a handler for base $base";

        # Could be more than one, line them up
    push @{$self->{bases}->{$base}}, $plugin_obj;
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;
    
            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

###########################################
package File::Comments::Target;
###########################################
use Sysadm::Install qw(:all);
use File::Basename;
use Log::Log4perl qw(:easy);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        path       => undef,
        dir        => undef,
        file_name  => undef,
        file_base  => undef,
        content    => undef,
        suffix     => undef,
        %options,
    };

    bless $self, $class;

    $self->load($self->{path}, $self->{content});

    return $self;
}

###########################################
sub load {
###########################################
    my($self, $path, $content) = @_;

    $self->{content}   = $content unless $content;
    $self->{path}      = $path;
    $self->{content}   = slurp $path unless defined $self->{content};

    $self->{file_name} = basename($path);

    $self->{dir}       = dirname($path);
    $self->{suffix}    = undef;
    $self->{file_base} = $self->{file_name};

    if(index($self->{file_name}, ".") >= 0) {
        ($self->{file_base}, $self->{suffix}) = 
            ($self->{file_name} =~ m#(.+)(\.[^.]*$)#);
    }

    DEBUG "Loaded file path=", def($path),
          " name=",            def($self->{file_name}),
          " dir=",             def($self->{dir}), 
          " suffix=",          def($self->{suffix}), 
          " base=",            def($self->{file_base}); 
}

###########################################
sub def {
###########################################
    return $_[0] if defined $_[0];
    return "**undef**";
}

File::Comments::make_accessor("File::Comments::Target", $_)
   for qw(path file_name file_base content suffix dir);

1;

__END__

=head1 NAME

File::Comments - Recognizes file formats and extracts format-specific comments

=head1 SYNOPSIS

    use File::Comments;

    my $snoop = File::Comments->new();

        # *----------------
        # | program.c:
        # | /* comment */
        # | main () {}
        # *----------------
    my $comments = $snoop->comments("program.c");
        # => [" comment "]

        # *----------------
        # | script.pl:
        # | # comment
        # | print "howdy!\n"; # another comment
        # *----------------
    my $comments = $snoop->comments("script.pl");
        # => [" comment", " another comment"]

        # or strip comments from a file:
    my $stripped = $snoop->stripped("script.pl");
        # => "print "howdy!\n";"

        # or just guess a file's type:
    my $type = $snoop->guess_type("program.c");    
        # => "c"

=head1 DESCRIPTION

File::Comments guesses the type of a given file, determines the format
used for comments, extracts all comments, and returns them as a reference
to an array of chunks. Alternatively, it strips all comments from a
file.

Currently supported are Perl scripts, C/C++ programs, Java, makefiles,
JavaScript, Python and PHP.

The plugin architecture used by File::Comments makes it easy to add new
formats. To support a new format, a new plugin module has to be installed.
No modifications to the File::Comments codebase are necessary, new 
plugins will be picked up automatically.

File::Comments can also be used to simply guess a file's type. It it
somewhat more flexible than File::MMagic and File::Type.
File types in File::Comments are typically based on file name suffixes
(*.c, *.pl, etc.). If no suffix is available, or a given suffix
is ambiguous (e.g. if several plugins have registered a handler for
the same suffix), then the file's content is used to narrow down the
possibilities and arrive at a decision.

WARNING: THIS MODULE IS UNDER DEVELOPMENT, QUALITY IS ALPHA. IF YOU
FIND BUGS, OR WANT TO CONTRIBUTE PLUGINS, PLEASE SEND THEM MY WAY.

=head2 FILE TYPES

Currently, the following plugins are included in the File::Comments 
distribution:

    ###############################################
    # plugin                              type    #
    ###############################################
      File::Comments::Plugin::C          c            (o)
      File::Comments::Plugin::Makefile   makefile  (X)
      File::Comments::Plugin::Perl       perl      (X)
      File::Comments::Plugin::JavaScript js           (o)
      File::Comments::Plugin::Java       java         (o)
      File::Comments::Plugin::HTML       html      (X)
      File::Comments::Plugin::Python     python       (o)
      File::Comments::Plugin::PHP        php          (o)

          (X) Fully implemented
          (o) Implemented with regular expressions, only works for
              easy cases until real parsers are employed.

The constants listed in the I<type> column are the strings returned
by the C<guess_type()> method.

=head1 Methods

=over 4

=item $snoop = File::Comments-E<gt>new()

Create a new comment extractor engine. This will automatically initialize
all plugins.

To avoid cold calls (L<Cold Calls>), set C<cold_calls> to a false value
(defaults to 1):

    $snoop = File::Comments->new( cold_calls => 0 );

By default, if no plugin can be found for a given file, C<File::Comments>
will throw a fatal error and C<die()>. If this is undesirable and
a default plugin should be used instead, it can be specified in
the constructor using the C<default_plugin> parameter:

    $snoop = File::Comments->new( 
      default_plugin => "File::Comments::Plugin::Makefile"
    );

=item $comments = $snoop-E<gt>comments("program.c");

Extract all comments from a file. After determining the file type
by either suffix or content (L<Cold Calls>), comments are extracted
as chunks and returned as a reference to an array.

To get a single string containing all comments, just join the chunks:

    my $comments_string = join '', @$comments;

=item $stripped_text = $snoop-E<gt>stripped("program.c");

Strip all comments from a file. After determining the file type
by either suffix or content (L<Cold Calls>), all comments are removed
and the stripped text is returned in a scalar.

=item $type = $snoop-E<gt>guess_type("script.pl")

Guess the type of a file, based on either suffix, or in absense of a suffix
via L<Cold Calls>. Return the result as a string: C<"c">, C<"makefile">,
C<"perl">, etc. (L<FILE TYPES>).

=item $snoop->suffix_registered("c")

Returns true if one of the plugins has registered the given suffix.

=back

=head2 Writing new plugins

Writing a new plugin to add functionality to the File::Comments framework
is as simple as defining a new module, derived from the baseclass of all
plugins, C<File::Comments::Plugin>. Three additional methods are needed: 
C<init()>, C<type()>, and C<comments()>.

C<init()> gets called when the mothership finds the plugin and
initializes it. This is the time to register extensions that the plugin
wants to handle.

The second mandatory method for a plugin is C<type()>, which returns
a string, indicating the type of the file examined. Usually this can
be done without further ado, since a basic plugin will called only
on files which it registered for by suffix. Exceptions to this are
explained later.

The third method is C<comments()>, which returns a reference to an 
array of comment lines. The content of the source file to be examined
will be available in 

    $self->{target}->{content}

by the time C<comments()> gets called.

And that's it. Here's a functional basic plugin, registering a new 
suffix ".odd" with the mothership and expecting files with comment lines
that start with C<ODDCOMMENT>:

    ###########################################
    package File::Comments::Plugin::Oddball;
    ###########################################

    use strict;
    use warnings;
    use File::Comments::Plugin;

    our $VERSION = "0.01";
    our @ISA     = qw(File::Comments::Plugin);

    ###########################################
    sub init {
    ###########################################
        my($self) = @_;
    
        $self->register_suffix(".odd");
    }

    ###########################################
    sub type {
    ###########################################
        my($self) = @_;
    
        return "odd";
    }

    ###########################################
    sub comments {
    ###########################################
        my($self) = @_;
    
        # Some code to extract all comments from 
        # $self->{target}->{content}:
        my @comments = ($self->{target}->{content} =~ /^ODDCOMMENT:(.*)/);
        return \@comments;
    }

    1;

=head2 Cold Calls

If a file doesn't have an extension or an extensions that's served by
multiple plugins, File::Comments will go shop around and ask all
plugins if they want to handle the file. The mothership calls 
each plugin's C<applicable()> method, passing it an object of
type C<File::Comments::Target>, which contains the following
fields:

When the plugin gets such a I<cold call> (indicated by the
third parameter to C<applicable()>, it can either accept or deny
the request. To arrive at a decision, it can peek into the target
object. The Perl plugin illustrates this:

    ###########################################
    sub applicable {
    ###########################################
        my($self, $target, $cold_call) = @_;
    
        return 1 unless $cold_call;
    
        return 1 if $target->{content} =~ /^#!.*perl\b/;

        return 0;
    }

If a plugin does not define a C<applicable()> method, a default method
is inherited from the base class C<File::Comments::Plugin>, which looks
like this:

    ###########################################
    sub applicable {
    ###########################################
        my($self, $target, $cold_call) = @_;

        return 0 if $cold_call;
        return 1;
    }

This will deny all I<cold calls> and only accept requests for files
with suffixes or base names the plugin has already signed up for.

=head2 Plugin Inheritance

Plugins can reuse existing plugins by inheritance. For example, if
you wanted to write a I<catch-all> plugin that takes over all cold
calls and handles comments like the C<Makefile> plugin, you can
simply use

    ###########################################
    package File::Comments::Plugin::Catchall;
    ###########################################

    use strict;
    use warnings;
    use File::Comments::Plugin;
    use File::Comments::Plugin::Makefile;

    our $VERSION = "0.01";
    our @ISA     = qw(File::Comments::Plugin::Makefile);

    ###########################################
    sub applicable {
    ###########################################
        my($self) = @_;
    
        return 1;
    }

C<File::Comments::Plugin::Catchall> just implements C<applicable()>
and inherits everything else from C<File::Comments::Plugin::Makefile>.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
