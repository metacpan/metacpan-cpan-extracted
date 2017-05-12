package Maypole::Plugin::Trace;

use warnings;
use strict;

use NEXT;
use Class::ISA();
use Class::Inspector();
use Data::Dumper();
use Scalar::Util();

use base 'Class::Data::Inheritable';

our $VERSION = '0.1';

# default to the most useful level
__PACKAGE__->mk_classdata(trace_level => 2);
__PACKAGE__->mk_classdata(only_trace_exported => 0);
__PACKAGE__->mk_classdata('extra_trace_classes');
__PACKAGE__->mk_classdata('trace_path');

=head1 NAME

Maypole::Plugin::Trace - trace calls in Maypole

=cut

=head1 SYNOPSIS

    use Maypole::Application qw/Trace/;
    
    # options:
    __PACKAGE__->trace_level(3);
    __PACKAGE__->only_trace_exported(1);

=head1 DESCRIPTION

Prints a trace of method entries and exits to C<STDERR>.

B<Requires the latest version of Maypole in SVN, or 2.11 when it's released>.

=over

=item trace_level

    __PACKAGE__->trace_level(1);
    
The default C<trace_level> is set to 2. 

The trace level must be set B<before calling C<setup>>.

    Level   Output
    ======================================================================
    0       none
    1       method entry and exit
    2       as above, but prints method arguments and return values
    3       uses Data::Dumper to expand method arguments and return values
                within Exported methods
    4       uses Data::Dumper to expand method arguments and return values 
                within all methods
    5       as 2, but also reports private methods (single leading _ in name)
    6       as 3, but also reports private methods (single leading _ in name)
    7       as 4, but also reports private methods (single leading _ in name)
    
Tracing is implemented for packages in the Maypole namespace, and in your 
application's namespace.

The characters C<E:> are printed in the left margin to indicate when an exported 
method is being processed.

At trace level 2, objects, e.g. in class C<Foo>, are represented as
C<Foo(OBJECT)>. This is to avoid potential overloaded stringification, which
causes deep recursion errors.

B<Note>: trace output is only generated for exported methods when they are
called via Maypole's own controller mechanism. So, for example, if a custom
method directly calls an exported method, the entry to and exit from the
exported method will not be registered in the trace output. This is a known bug,
suggestions for how to fix it would be great.

=item only_trace_exported

    __PACKAGE__->only_trace_exported(1)
    
Turn off tracing except within Exported methods. Default is 0 - trace all
methods.

=item extra_trace_classes

    __PACKAGE__->extra_trace_classes('Some::Problem::Package');
    
    # or
    __PACKAGE__->extra_trace_classes( [ 'Some::Problem::Package', 
                                        'Another::Buggy::Monster',
                                        ] );
    
Adds the specified package(s) to the list of traced packages.    

=item trace_path

True or false, default false. 

Shows the request path in trace output.

No path is shown for methods that do not include the Maypole request object in
their parameters. This includes methods run before or after a request, most
methods in non-Maypole packages, and some methods within the Maypole stack.
Also, the path is not available until after C<parse_path()> has returned.

=item setup

Configures tracing.

=back

=cut

sub setup
{
    my $class = shift;
    
    # load models etc first
    $class->NEXT::DISTINCT::setup(@_);
    
    # our version manually traces Exported methods
    {
        no warnings 'redefine';
        *Maypole::Model::Base::process = \&__process;
    }
    
    my $trace_level = $class->trace_level or return;
    my $show_private;
    if ($trace_level == 5)
    {
        $show_private = 1;
        $trace_level = 2;
    }
    if ($trace_level == 6)
    {
        $show_private = 1;
        $trace_level = 3;
    }
    if ($trace_level == 7)
    {
        $show_private = 1;
        $trace_level = 4;
    }
    
    my @classes = Class::ISA::self_and_super_path($class);
    push @classes, Class::ISA::self_and_super_path($class->config->model);
    push @classes, @{$class->config->classes};
    push @classes, Class::ISA::self_and_super_path($class->config->view);
    
    my @extra_trace_classes;
    if (my $extras = $class->extra_trace_classes)
    {
        @extra_trace_classes = ref($extras) ? @$extras : ($extras);
        push @classes, @extra_trace_classes;
    }
    
    my %done;   # ensure no subs are traced more than once
    
    foreach my $trace_class (@classes)
    {
        # 'expanded' gives an arrayref for each function:
        # [0] - full name
        # [1] - class
        # [2] - function name
        # [3] - coderef
        my @public = $show_private ? () : ('public');
        my $functions = Class::Inspector->methods($trace_class, @public, 'expanded');
        
        # never trace super-private methods - in particular, don't trace 
        # the trace methods. Might revisit this.
        @$functions = grep { $_->[2] !~ /^__/ } @$functions;
        
        # don't trace stuff outside our app, or Maypole, or extra requested packages
        my @our_functions = grep { $_->[1] =~ /(?:Maypole|MVC|$class)/ } @$functions;
        
        if (@extra_trace_classes)
        {
            foreach my $extra_class (@extra_trace_classes)
            {
                foreach my $function (@$functions)
                {
                    push(@our_functions, $function) if $function->[1] eq $extra_class;
                }
            }
        }
        
        @$functions = @our_functions;
        
        foreach my $function (@$functions)
        {
            next if $done{ $function->[0] }++; 
            $class->__traceize( $function->[1], 
                                $function->[2], 
                                $trace_level, 
                                $class->only_trace_exported,
                                $class->trace_path,
                                );
        }
    }
    
    #warn "Tracing these subs:\n", join "\n", sort keys %done;
}

sub __traceize
{
    my ($class, $namespace, $function, $level, $only_exported, $show_path) = @_;
    
    my $coderef = $namespace->can($function);
    
    my $traced = sub
    {
        __trace_entry(0, $level, $only_exported, $show_path, $namespace, $function, @_);

        if (wantarray)              # list context
        {
            my @return = $coderef->(@_);
            __trace_exit($level, $only_exported, $show_path, $namespace, $function, @return);
            return @return;
        }
        elsif(defined wantarray)    # scalar context
        {
            my $return = $coderef->(@_);
            __trace_exit($level, $only_exported, $show_path, $namespace, $function, $return);
            return $return;
        }
        else                        # void context
        {
            $coderef->(@_);
            __trace_exit($level, $only_exported, $show_path, $namespace, $function);
            return;
        }
    };
    
    # replace original sub with the traced version
    # TODO: don't know how to preserve attributes
    return if $class->config->model->method_attrs($function);
    
    {
        no strict 'refs';
        no warnings 'redefine';
        *{"$namespace\::$function"} = $traced;
    }
}

{
    # note - these functions are also called from Mp::Model::Base::process()
    
    my $indent = 0;
    my $in_exported = '';
    my $path = '';
    
    # not a method
    sub __trace_entry
    {
        my ($is_exported, $level, $only_exported, $show_path, $namespace, $function, @args) = @_;
        
        if (ref($args[0]) and UNIVERSAL::isa($args[0], 'Maypole'))
        {
            # NOTE: this *must* be by direct hash access, otherwise we're 
            # calling a traced method, and infinitely recurse
            $path = $args[0]->{path};
        }
        else
        {
            $path = '';
        }
        
        $in_exported = "$namespace\::$function" if $is_exported;

        return if ($only_exported and not length $in_exported);
        
        my $msg = "   " x $indent++ . "==> $namespace\::$function";
        $msg =~ s/^../E:/ if $in_exported;
        $msg = "$path: $msg" if $show_path and $path;
        
        if ($level == 2)
        {        
            @args = __prep_args2(@args);
            $msg .=  '( '.join(', ', @args)." )\n";
        }
        elsif ($level == 3)
        {        
            @args = __prep_args3(@args);
            $msg .=  '( '.join(', ', @args)." )\n";
        }
        elsif ($level > 3)
        {
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Indent = 1;
            $msg .= '( '.Data::Dumper::Dumper(\@args)." )\n";
        }
        
        warn $msg;
    }
    
    # not a method 
    sub __trace_exit
    {
        my ($level, $only_exported, $show_path, $namespace, $function, @args) = @_;
        
        return if ($only_exported and not length $in_exported);
        
        my $msg = "   " x --$indent . "<== $namespace\::$function";
        $msg =~ s/^../E:/ if $in_exported;
        $msg = "$path: $msg" if $show_path and $path;
        
        if ($level == 2)
        {
            @args = __prep_args2(@args);
            $msg .= ' return( '.join(', ', @args)." )\n";
        }
        elsif ($level == 3)
        {        
            @args = __prep_args3(@args);
            $msg .=  '( '.join(', ', @args)." )\n";
        }
        elsif ($level > 3)
        {
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Indent = 1;
            $msg .= ' return( '.Data::Dumper::Dumper(\@args)." )\n";
        }
        
        # completed processing an exported method
        $in_exported = '' if "$namespace\::$function" eq $in_exported;
        
        warn $msg;
    }

    # expand args inside Exported method
    sub __prep_args3
    {
        my @args = @_;
        
        if ($in_exported)
        {
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Indent = 1;
            @args = (Data::Dumper::Dumper(\@args));
        }
        else
        {
            @args = __prep_args2(@args);
        }
        
        return @args;
    }
}

sub __prep_args2
{
    my @args = @_;
    
    map { 
        my $str = $_;
        if (defined $str)
        {
            if (! ref $str)
            {
                $str = "'$str'";
            }
            elsif(Scalar::Util::blessed($str)) 
            {
                # avoid calling overloaded stringification - 
                # causes deep recursion
                $str = ref($str).'(OBJECT)';
            }
        }
        else
        {
            $str = 'undef'
        }; 

        #Text::Elide::elide($_, 50) 
        substr $str, 0, 50, "...'";
    } @args;
}

# we replace Maypole::Model::Base::process with this
sub __process {
    my ( $class, $r ) = @_;
    my $method = $r->action;
    return if $r->{template};    # Authentication has set this, we're done.

    $r->{template} = $method;
    my $obj = $class->fetch_objects($r);
    $r->objects([$obj]) if $obj;
    
    # have to trace manually, because can't replace Exported methods with 
    # self-traceing versions - see trace methods in Maypole.pm
    # The '1' indicates the method is exported.
    my $trace_level = $r->trace_level if $r->can('trace_level');
    Maypole::Plugin::Trace::__trace_entry(1, $trace_level, $r->only_trace_exported, $r->trace_path, $class, $method, $r, $obj, @{ $r->args } )
        if $trace_level;
        
    $class->$method( $r, $obj, @{ $r->{args} } );
    
    Maypole::Plugin::Trace::__trace_exit($trace_level, $r->only_trace_exported, $r->trace_path, $class, $method, $r, $obj, @{ $r->args } )
        if $trace_level;
    
    return; # previously, would implicitly return whatever the $method call 
            # returned, and the return value was ignored
}



=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-plugin-trace@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Plugin-Trace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Maypole::Plugin::Trace
