package Gnuplot::Builder::Script;
use strict;
use warnings;
use Gnuplot::Builder::PrototypedData;
use Gnuplot::Builder::Util qw(quote_gnuplot_str);
use Gnuplot::Builder::Process;
use Scalar::Util qw(weaken blessed refaddr);
use Carp;
use overload '""' => "to_string";

sub new {
    my ($class, @set_args) = @_;
    my $self = bless {
        pdata => undef,
        parent => undef,
    };
    $self->_init_pdata();
    if(@set_args) {
        $self->set(@set_args);
    }
    return $self;
}

sub _init_pdata {
    my ($self) = @_;
    weaken $self;
    $self->{pdata} = Gnuplot::Builder::PrototypedData->new(
        entry_evaluator => sub {
            my ($key, $value_code) = @_;
            if(defined($key)) {
                return $value_code->($self, substr($key, 1));
            }else {
                return $value_code->($self);
            }
        }
    );
}

sub add {
    my ($self, @sentences) = @_;
    foreach my $sentence (@sentences) {
        $self->{pdata}->add_entry($sentence);
    }
    return $self;
}

sub _set_entry {
    my ($self, $prefix, $quote, @pairs) = @_;
    $self->{pdata}->set_entry(
        entries => \@pairs,
        key_prefix => $prefix,
        quote => $quote,
    );
    return $self;
}

sub set {
    my ($self, @pairs) = @_;
    return $self->_set_entry("o", 0, @pairs);
}

*set_option = *set;

sub setq {
    my ($self, @pairs) = @_;
    return $self->_set_entry("o", 1, @pairs);
}

*setq_option = *setq;

sub unset {
    my ($self, @names) = @_;
    return $self->set(map { $_ => undef } @names);
}

sub _get_entry {
    my ($self, $prefix, $name) = @_;
    croak "name cannot be undef" if not defined $name;
    return $self->{pdata}->get_resolved_entry("$prefix$name");
}

sub get_option {
    my ($self, $name) = @_;
    return $self->_get_entry("o", $name);
}

sub _delete_entry {
    my ($self, $prefix, @names) = @_;
    foreach my $name (@names) {
        croak "name cannot be undef" if not defined $name;
        $self->{pdata}->delete_entry("$prefix$name");
    }
    return $self;
}

sub delete_option {
    my ($self, @names) = @_;
    return $self->_delete_entry("o", @names);
}

sub _create_statement {
    my ($raw_key, $value) = @_;
    return $value if !defined $raw_key;
    my ($prefix, $name) = (substr($raw_key, 0, 1), substr($raw_key, 1));
    my @words = ();
    if($prefix eq "o") {
        @words = defined($value) ? ("set", $name, $value) : ("unset", $name);
    }elsif($prefix eq "d") {
        @words = defined($value) ? ($name, "=", $value) : ("undefine", $name);
    }else {
        confess "Unknown key prefix: $prefix";
    }
    return join(" ", grep { "$_" ne "" } @words);
}

sub to_string {
    my ($self) = @_;
    my $result = "";
    $self->{pdata}->each_resolved_entry(sub {
        my ($raw_key, $values) = @_;
        foreach my $value (@$values) {
            my $statement = _create_statement($raw_key, $value);
            $result .= $statement;
            $result .= "\n" if $statement !~ /\n$/;
        }
    });
    return $result;
}

sub define {
    my ($self, @pairs) = @_;
    return $self->_set_entry("d", 0, @pairs);
}

*set_definition = *define;

sub undefine {
    my ($self, @names) = @_;
    return $self->define(map { $_ => undef } @names);
}

sub get_definition {
    my ($self, $name) = @_;
    return $self->_get_entry("d", $name);
}

sub delete_definition {
    my ($self, @names) = @_;
    return $self->_delete_entry("d", @names);
}

sub set_parent {
    my ($self, $parent) = @_;
    if(!defined($parent)) {
        $self->{parent} = undef;
        $self->{pdata}->set_parent(undef);
        return $self;
    }
    if(!blessed($parent) || !$parent->isa("Gnuplot::Builder::Script")) {
        croak "parent must be a Gnuplot::Builder::Script"
    }
    $self->{parent} = $parent;
    $self->{pdata}->set_parent($parent->{pdata});
    return $self;
}

sub get_parent { return $_[0]->{parent} }

*parent = *get_parent;

sub new_child {
    my ($self) = @_;
    return Gnuplot::Builder::Script->new->set_parent($self);
}

sub _collect_dataset_params {
    my ($dataset_arrayref) = @_;
    my @params_str = ();
    my @dataset_objects = ();
    foreach my $dataset (@$dataset_arrayref) {
        my $ref = ref($dataset);
        if(!$ref) {
            push(@params_str, $dataset);
        }else {
            if(!$dataset->can("params_string") || !$dataset->can("write_data_to")) {
                croak "You cannot use $ref object as a dataset.";
            }
            my ($param_str) = $dataset->params_string();
            push(@params_str, $param_str);
            push(@dataset_objects, $dataset);
        }
    }
    return (\@params_str, \@dataset_objects);
}

sub _wrap_writer_to_detect_empty_data {
    my ($writer) = @_;
    my $ended_with_newline = 0;
    my $data_written = 0;
    my $wrapped_writer = sub {
        my @nonempty_data = grep { defined($_) && $_ ne "" } @_;
        return if !@nonempty_data;
        $data_written = 1;
        $ended_with_newline = ($nonempty_data[-1] =~ /\n$/);
        $writer->(join("", @nonempty_data));
    };
    return ($wrapped_writer, \$data_written, \$ended_with_newline);
}

sub _write_inline_data {
    my ($writer, $dataset_objects_arrayref) = @_;
    my ($wrapped_writer, $data_written_ref, $ended_with_newline_ref) =
        _wrap_writer_to_detect_empty_data($writer);
    foreach my $dataset (@$dataset_objects_arrayref) {
        $$data_written_ref = $$ended_with_newline_ref = 0;
        $dataset->write_data_to($wrapped_writer);
        next if !$$data_written_ref;
        $writer->("\n") if !$$ended_with_newline_ref;
        $writer->("e\n");
    }
}

sub _wrap_commands_with_output {
    my ($commands_ref, $output_filename) = @_;
    if(defined($output_filename)) {
        unshift @$commands_ref, "set output " . quote_gnuplot_str($output_filename);
        push @$commands_ref, "set output";
    }
}

sub _draw_with {
    my ($self, %args) = @_;
    my $plot_command = $args{command};
    my $dataset = $args{dataset};
    croak "dataset parameter is mandatory" if not defined $dataset;
    if(ref($dataset) ne "ARRAY") {
        $dataset = [$dataset];
    }
    croak "at least one dataset is required" if !@$dataset;

    my $plotter = sub {
        my $writer = shift;
        my ($params, $dataset_objects) = _collect_dataset_params($dataset);
        $writer->("$plot_command " . join(",", @$params) . "\n");
        _write_inline_data($writer, $dataset_objects);
    };
    my @commands = ($plotter);
    return $self->run_with(
        do => \@commands,
        _pair_slice(\%args, qw(writer async output no_stderr))
    );
}

sub _pair_slice {
    my ($hash_ref, @keys) = @_;
    return map { exists($hash_ref->{$_}) ? ($_ => $hash_ref->{$_}) : () } @keys;
}

sub plot_with {
    my ($self, %args) = @_;
    return $self->_draw_with(%args, command => "plot");
}

sub splot_with {
    my ($self, %args) = @_;
    return $self->_draw_with(%args, command => "splot");
}

sub plot {
    my ($self, @dataset) = @_;
    return $self->_draw_with(command => "plot", dataset => \@dataset);
}

sub splot {
    my ($self, @dataset) = @_;
    return $self->_draw_with(command => "splot", dataset => \@dataset);
}

sub multiplot_with {
    my ($self, %args) = @_;
    my $do = $args{do};
    croak "do parameter is mandatory" if not defined $do;
    croak "do parameter must be a code-ref" if ref($do) ne "CODE";
    my $wrapped_do = sub {
        my $writer = shift;
        my ($wrapped_writer, $data_written_ref, $ended_with_newline_ref) =
            _wrap_writer_to_detect_empty_data($writer);
        $do->($wrapped_writer);
        if($$data_written_ref && !$$ended_with_newline_ref) {
            $writer->("\n");
        }
    };
    my $multiplot_command =
        (defined($args{option}) && $args{option} ne "")
            ? "set multiplot $args{option}" : "set multiplot";
    my @commands = ($multiplot_command, $wrapped_do, "unset multiplot");
    return $self->run_with(
        do => \@commands,
        _pair_slice(\%args, qw(writer async output no_stderr))
    );
}

sub multiplot {
    my ($self, $option, $code) = @_;
    if(@_ == 2) {
        $code = $option;
        $option = "";
    }
    croak "code parameter is mandatory" if not defined $code;
    croak "code parameter must be a code-ref" if ref($code) ne "CODE";
    return $self->multiplot_with(do => $code, option => $option);
}

our $_context_writer = undef;

sub run_with {
    my ($self, %args) = @_;
    my $commands = $args{do};
    if(!defined($commands)) {
        $commands = [];
    }elsif(ref($commands) ne "ARRAY") {
        $commands = [$commands];
    }
    _wrap_commands_with_output($commands, $self->_plotting_option(\%args, "output"));
    my $do = sub {
        my $writer = shift;
        (!defined($_context_writer) || refaddr($_context_writer) != refaddr($writer))
            and local $_context_writer = $writer;
        
        $writer->($self->to_string);
        foreach my $command (@$commands) {
            if(ref($command) eq "CODE") {
                $command->($writer);
            }else {
                $command = "$command";
                $writer->($command);
                $writer->("\n") if $command !~ /\n$/;
            }
        }
    };

    my $result = "";
    my $got_writer = $self->_plotting_option(\%args, "writer");
    if(defined($got_writer)) {
        $do->($got_writer);
    }elsif(defined($_context_writer)) {
        $do->($_context_writer);
    }else {
        $result = Gnuplot::Builder::Process->with_new_process(
            async => $self->_plotting_option(\%args, "async"),
            do => $do,
            no_stderr => $self->_plotting_option(\%args, "no_stderr")
        );
    }
    return $result;
}

sub _plotting_option {
    my ($self, $given_args_ref, $key) = @_;
    return (exists $given_args_ref->{$key})
        ? $given_args_ref->{$key}
        : $self->get_plot($key);
}

sub run {
    my ($self, @commands) = @_;
    return $self->run_with(do => \@commands);
}

my %KNOWN_PLOTTING_OPTIONS = map { ($_ => 1) } qw(output no_stderr writer async);

sub _check_plotting_option {
    my ($arg_name) = @_;
    croak "Unknown plotting option: $arg_name" if !$KNOWN_PLOTTING_OPTIONS{$arg_name};
}

sub set_plot {
    my ($self, %opts) = @_;
    foreach my $key (keys %opts) {
        _check_plotting_option($key);
        $self->{pdata}->set_attribute(
            key => $key,
            value => $opts{$key}
        );
    }
    return $self;
}

sub get_plot {
    my ($self, $arg_name) = @_;
    _check_plotting_option($arg_name);
    croak "arg_name cannot be undef" if not defined $arg_name;
    return $self->{pdata}->get_resolved_attribute($arg_name);
}

sub delete_plot {
    my ($self, @arg_names) = @_;
    foreach my $arg_name (@arg_names) {
        _check_plotting_option($arg_name);
        $self->{pdata}->delete_attribute($arg_name) 
    }
    return $self;
}

sub Lens {
    my ($self, $key) = @_;
    require Gnuplot::Builder::Lens;
    return Gnuplot::Builder::Lens->new(
        "get_option", "set_option", $key
    );
}

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Script - object-oriented builder for gnuplot script

=head1 SYNOPSIS

    use Gnuplot::Builder::Script;
    
    my $builder = Gnuplot::Builder::Script->new();
    $builder->set(
        terminal => 'png size 500,500 enhanced',
        grid     => 'x y',
        xrange   => '[-10:10]',
        yrange   => '[-1:1]',
        xlabel   => '"x" offset 0,1',
        ylabel   => '"y" offset 1,0',
    );
    $builder->setq(output => 'sin_wave.png');
    $builder->unset("key");
    $builder->define('f(x)' => 'sin(pi * x)');
    print $builder->plot("f(x)"); ## output sin_wave.png
    
    my $child = $builder->new_child;
    $child->define('f(x)' => 'cos(pi * x)'); ## override parent's setting
    $child->setq(output => 'cos_wave.png');  ## override parent's setting
    print $child->plot("f(x)");              ## output cos_wave.png

=head1 DESCRIPTION

L<Gnuplot::Builder::Script> is a builder object for a gnuplot script.

The advantages of this module over just printing script text are:

=over

=item *

It keeps option settings and definitions in a hash-like data structure.
So you can change those items individually.

=item *

It accepts code-refs for script sentences, option settings and definitions.
They are evaluated lazily every time it builds the script.

=item *

It supports prototype-based inheritance similar to JavaScript objects.
A child builder can override its parent's settings.

=back

=head1 CLASS METHODS

=head2 $builder = Gnuplot::Builder::Script->new(@set_args)

The constructor.

The argument C<@set_args> is optional. If it's absent, it creates an empty builder.
If it's set, C<@set_args> is directly given to C<set()> method.

=head1 OBJECT METHODS - BASICS

Most object methods return the object itself, so that you can chain those methods.

=head2 $script = $builder->to_string()

Build and return the gnuplot script string.

=head2 $builder = $buider->add($sentence, ...)

Add gnuplot script sentences to the C<$builder>.

This is a low-level method. B<< In most cases you should use C<set()> and C<define()> methods below. >>

C<$sentences> is a string or a code-ref.
A code-ref is evaluated in list context when it builds the script.
The returned list of strings are added to the script.

You can pass more than one C<$sentence>s.

    $builder->add(<<'EOT');
    set title "sample"
    set xlabel "iteration"
    EOT
    my $unit = "sec";
    $builder->add(sub { qq{set ylabel "Time [$unit]"} });

=head1 OBJECT METHODS - GNUPLOT OPTIONS

Methods to manipulate gnuplot options (the "set" and "unset" commands).

=head2 $builder = $builder->set($opt_name => $opt_value, ...)

Set a gnuplot option named C<$opt_name> to C<$opt_value>.
You can set more than one name-value pairs.

C<$opt_value> is either C<undef>, a string, an array-ref of strings, a code-ref or a blessed object.

=over

=item *

If C<$opt_value> is C<undef>, the "unset" command is generated for the option.

=item *

If C<$opt_value> is a string, the option is set to that string.

=item *

If C<$opt_value> is an array-ref, the "set" command is repeated for each element in it.
If the array is empty, no "set" or "unset" command is generated.

    $builder->set(
        terminal => 'png size 200,200',
        key      => undef,
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
        
    $builder->set(
        arrow => ['1 from 0,0 to 0,1', '2 from 100,0 to 0,100']
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
    ## => set arrow 1 0,0 to 0,1
    ## => set arrow 2 from 100,0 to 0,100

=item *

If C<$opt_value> is a code-ref,
it is evaluated in list context when the C<$builder> builds the script.

    @returned_values = $opt_value->($builder, $opt_name)

The C<$builder> and C<$opt_name> are given to the code-ref.

Then, the option is generated as if C<< $opt_name => \@returned_values >> was set.
You can return single C<undef> to "unset" the option.

    my %SCALE_LABEL = (1 => "", 1000 => "k", 1000000 => "M");
    my $scale = 1000;
    $builder->set(
        xlabel => sub { qq{"Traffic [$SCALE_LABEL{$scale}bps]"} },
    );

=item *

If C<$opt_value> is a blessed object, it's stringification (i.e. C<< "$opt_value" >>) is evaluated when C<$builder> builds the parameters.
You can retrieve the object by C<get_option()> method.

=back

The options are stored in the C<$builder>'s hash-like structure,
so you can change those options individually.

Even if the options are changed later, their order in the script is unchanged.

    $builder->set(
        terminal => 'png size 500,500',
        xrange => '[100:200]',
        output => '"foo.png"',
    );
    $builder->to_string();
    ## => set terminal png size 500,500
    ## => set xrange [100:200]
    ## => set output "foo.png"
    
    $builder->set(
        terminal => 'postscript eps size 5.0,5.0',
        output => '"foo.eps"'
    );
    $builder->to_string();
    ## => set terminal postscript eps size 5.0,5.0
    ## => set xrange [100:200]
    ## => set output "foo.eps"

Note that you are free to use any string as C<$opt_name>.
In fact, there may be more than one way to build the same script.

    $builder1->set(
        'style data' => 'lines',
        'style fill' => 'solid 0.5'
    );
    $builder2->set(
        style => ['data lines', 'fill solid 0.5']
    );

In the above example, C<$builder1> and C<$builder2> generate the same script.
However, C<$builder2> cannot change the style for "data" or "fill" individually, while C<$builder1> can.


=head2 $builder = $builder->set($options)

If C<set()> method is called with a single string argument C<$options>,
it is parsed to set options.

    $builder->set(<<'EOT');
    xrange = [-5:10]
    output = "foo.png"
    grid
    -key
    
    ## terminal = png size 100,200
    terminal = pngcairo size 400,800
    
    tics = mirror in \
           rotate autojustify
    
    arrow = 1 from 0,10 to 10,0
    arrow = 2 from 5,5  to 10,10
    EOT

Here is the parsing rule:

=over

=item *

Each line is a "set" or "unset" command.

=item *

A "set" line is a pair of option name and value with "=" between them.

    OPT_NAME = OPT_VALUE

=item *

An "unset" line is the option name with leading "-".

    -OPT_NAME

=item *

White spaces around OPT_NAME and OPT_VALUE are ignored.

=item *

If OPT_VALUE is an empty string in "set" line, you can omit "=".

=item *

Lines with a trailing backslash continue to the next line.
The effect is as if the backslash and newline were not there.

=item *

Empty lines are ignored.

=item *

Lines starting with "#" are ignored.

=item *

You can write more than one lines for the same OPT_NAME.
It's the same effect as C<< set($opt_name => [$opt_value1, $opt_value2, ...]) >>.

=back

=head2 $builder = $builder->set_option(...)

C<set_option()> is alias of C<set()>.

=head2 $builder = $builder->setq(...)

C<setq()> method is the same as C<set()> except that eventual option values are quoted.

This method is useful for setting "title", "xlabel", "output" etc.

    $builder->setq(
        output => "hoge.png",
        title  => "hoge's values",
    );
    $builder->to_string;
    ## => set output 'hoge.png'
    ## => set title 'hoge''s values'

If the option value is a list, it quotes the all elements.

=head2 $builder = $builder->setq_option(...)

C<setq_option()> is alias of C<setq()>.


=head2 $builder = $builder->unset($opt_name, ...)

Short-cut for C<< set($opt_name => undef) >>.
It generates "unset" command for the option.

You can specify more that one C<$opt_name>s.

=head2 @opt_values = $builder->get_option($opt_name)

Get the option values for C<$opt_name>. In list context, it returns all values for C<$opt_name>.
In scalar context, it returns only the first value.

If C<$opt_name> is set in the C<$builder>, it returns its values.
If a code-ref is set to the C<$opt_name>, it is evaluated and its results are returned.
If a blessed object is set to the C<$opt_name>, that object is returned.

If C<$opt_name> is not set in the C<$builder>, the values of C<$builder>'s parent are returned.
If C<$builder> does not have parent, it returns an empty list in list context or C<undef> in scalar context.

This method may return both C<< (undef) >> and C<< () >>.
Returning C<< (undef) >> means the option is "unset" explicitly,
while returning an empty list means no "set" or "unset" sentence for the option.
If you want to distinguish those two cases, you must call C<get_option()> in list context.


=head2 $builder = $builder->delete_option($opt_name, ...)

Delete the values for C<$opt_name> from the C<$builder>.
You can specify more than one C<$opt_name>s.

After C<$opt_name> is deleted, C<get_option($opt_name)> will search the C<$builder>'s parent for the values.

Note the difference between C<delete_option()> and C<unset()>.
While C<unset($opt_name)> will generate "unset" sentence for the option,
C<delete_option($opt_name)> will be likely to generate no sentence (well, strictly speaking, it depends on the parent).

C<delete_option($opt_name)> and C<< set($opt_name => []) >> are also different if the C<$builder> is a child.
C<set()> always overrides the parent setting, while C<delete_option()> resets such overrides.


=head1 OBJECT METHODS - GNUPLOT DEFINITIONS

Methods to manipulate user-defined variables and functions.

Most methods in this category are analogous to the methods in L</OBJECT METHODS - GNUPLOT OPTIONS>.

    +---------------+-------------------+
    |    Options    |    Definitions    |
    +===============+===================+
    | set           | define            |
    | set_option    | set_definition    |
    | setq          | (N/A)             |
    | setq_option   | (N/A)             |
    | unset         | undefine          |
    | get_option    | get_definition    |
    | delete_option | delete_definition |
    +---------------+-------------------+

I'm sure you can understand this analogy by this example.

    $builder->set(
        xtics => 10,
        key   => undef
    );
    $builder->define(
        a      => 100,
        'f(x)' => 'sin(a * x)',
        b      => undef
    );
    $builder->to_string();
    ## => set xtics 10
    ## => unset key
    ## => a = 100
    ## => f(x) = sin(a * x)
    ## => undefine b

=head2 $builder = $builder->define($def_name => $def_value, ...)

=head2 $builder = $builder->define($definitions)

Set function and variable definitions. See C<set()> method.

=head2 $builder = $builder->set_definition(...)

Alias for C<define()> method.

=head2 $builder = $builder->undefine($def_name, ...)

Short-cut for C<< define($def_name => undef) >>. See C<unset()> method.

=head2 @def_values = $builder->get_definition($def_name)

Get definitions from the C<$builder>. See C<get_option()> method.

=head2 $builder = $builder->delete_definition($def_name, ...)

Delete definitions from the C<$builder>. See C<delete_option()> method.

=head1 OBJECT METHODS - PLOTTING

Methods for plotting.

All plotting methods are non-mutator, that is, they don't change the state of the C<$builder>.
This means you can plot different datasets with the same settings.

By default, plotting methods run a gnuplot process background, and let it do the plotting work.
The variable C<@Gnuplot::Builder::Process::COMMAND> is used to start the gnuplot process.
See L<Gnuplot::Builder::Process> for detail.

=head2 $result = $builder->plot($dataset, ...)

Build the script and plot the given C<$dataset>s with gnuplot's "plot" command.
This method lets a gnuplot process do the actual job.

You can specify more than one C<$dataset>s to plot.

The return value C<$result> is the data that the gnuplot process writes to STDOUT and STDERR (by default).

Usually you should use a L<Gnuplot::Builder::Dataset> object for C<$dataset>.
In this case, you can skip the rest of this section.

In detail, C<$dataset> is either a string or an object.

=over

=item *

If C<$dataset> is a string, it's treated as the dataset parameters for "plot" command.

    $builder->plot(
        'sin(x) with lines lw 2',
        'cos(x) with lines lw 5',
        '"datafile.dat" using 1:3 with points ps 4'
    );

=item *

The above code plots "sin(x)" and "cos(x)" curves and data points in the file "datafile.dat".

If C<$dataset> is an object, it must implement C<params_string()> and C<write_data_to()> methods (like L<Gnuplot::Builder::Dataset>).

C<params_string()> method is supposed to return a string of the dataset parameters,
and C<write_data_to()> method provide the inline data if it has.

The two methods are called like

    ($params_str) = $dataset->params_string();
    $dataset->write_data_to($writer);

where C<$writer> is a code-ref that you must call with the inline data you have.

    package My::Data;
    
    sub new {
        my ($class, $x_data, $y_data) = @_;
        return bless { x => $x_data, y => $y_data }, $class;
    }
    
    sub params_string { q{"-" using 1:2 title "My Data" with lp} }
    
    sub write_data_to {
        my ($self, $writer) = @_;
        foreach my $i (0 .. $#{$self->{x}}) {
            my ($x, $y) = ($self->{x}[$i], $self->{y}[$i]);
            $writer->("$x $y\n");
        }
    }
    
    $builder->plot(My::Data->new([1,2,3], [1,4,9]));


If C<write_data_to()> method doesn't pass any data to the C<$writer>,
the C<plot()> method doesn't generate the inline data section.


=back

=head2 $result = $builder->plot_with(%args)

Plot with more functionalities than C<plot()> method.

Fields in C<%args> are as follows.
Note that you can store default values for some arguments in C<$builder>.
See L<"OBJECT METHODS - PLOTTING OPTIONS"> for detail.

=over

=item C<dataset> => DATASETS (mandatory)

Datasets to plot. It is either a dataset or an array-ref of datasets.
See C<plot()> for specification of datasets.

=item C<output> => OUTPUT_FILENAME (optional)

If set, "set output" command is printed just before "plot" command,
so that it would output the plot to the specified file.
The specified file name is quoted.
After "plot" command, it prints "set output" command with no argument to unlock the file.

If not set, it won't print "set output" commands.

=item C<no_stderr> => BOOL (optional, default: C<$Gnuplot::Builder::Process::NO_STDERR>)

If set to true, the return value C<$result> contains gnuplot's STDOUT only. It doesn't contain STDERR.
If false, C<$result> contains both STDOUT and STDERR.
This option has no effect if C<writer> or C<async> is set.

By default, it's false. You can change the default by C<$Gnuplot::Builder::Process::NO_STDERR> package varible.

=item C<writer> => CODE-REF (optional)

A code-ref to receive the whole script string instead of the gnuplot process.
If set, it is called one or more times with the script string that C<$builder> builds.
In this case, the return value C<$result> will be an empty string, because no gnuplot process is started.

If not set, C<$builder> streams the script into the gnuplot process.
The return value C<$result> will be the data the gnuplot process writes to STDOUT and STDERR.

=item C<async> => BOOL (optional, default: C<$Gnuplot::Builder::Process::ASYNC>)

If set to true, it won't wait for the gnuplot process to finish.
In this case, the return value C<$result> will be an empty string.

Using C<async> option, you can run more than one gnuplot processes to do the job.
However, the maximum number of gnuplot processes are limited to
the variable C<$Gnuplot::Builder::Process::MAX_PROCESSES>.
See L<Gnuplot::Builder::Process> for detail.

If set to false, it waits for the gnuplot process to finish and return its output.

By default it's false, but you can change the default by C<$Gnuplot::Builder::Process::ASYNC> package variable.

=back

    my $script = "";
    $builder->plot_with(
        dataset => ['sin(x)', 'cos(x)'],
        output  => "hoge.eps",
        writer  => sub {
            my ($script_part) = @_;
            $script .= $script_part;
        }
    );
    
    $script;
    ## => set output 'hoge.eps'
    ## => plot sin(x),cos(x)
    ## => set output


=head2 $result = $builder->splot($dataset, ...)

Same as C<plot()> method except it uses "splot" command.

=head2 $result = $builder->splot_with(%args)

Same as C<plot_with()> method except it uses "splot" command.

=head2 $result = $builder->multiplot($option, $code)

Build the script, input the script into a new gnuplot process,
start a new multiplot context and execute the C<$code> in the context.
This method lets a gnuplot process do the actual job.

C<$option> is the option string for "set multiplot" command. C<$option> is optional.

Mandatory argument C<$code> is a code-ref that is executed immediately.
The C<$code> is called like

    $code->($writer)

where C<$writer> is a code-ref that you can call to write any data to the gnuplot process.

The return value C<$result> is the data that the gnuplot process writes to STDOUT and STDERR (by default).

The script written to the C<$writer> is enclosed by "set multiplot" and "unset multiplot" commands,
and passed to the gnuplot process.
So the following example creates a multiplot figure of sin(x) and cos(x).

    $builder->multiplot('layout 2,1', sub {
        my $writer = shift;
        $writer->("plot sin(x)\n");
        $writer->("plot cos(x)\n");
    });

If you call plotting methods (including C<multiplot()> itself) without explicit writer in the C<$code> block,
those methods won't start a new gnuplot process.
Instead they write the script to the C<$writer> that is given by the enclosing C<multiplot()> method.

    $builder->multiplot(sub {
        my $writer = shift;
        my $another_builder = Gnuplot::Builder::Script->new;
        
        $another_builder->plot("sin(x)");   ## This is the same as below
        $another_builder->plot_with(
            dataset => "sin(x)",
            writer => $writer
        );
    });

You can mix using L<Gnuplot::Builder::Script> objects and using C<$writer> directly in a single code block.
A good rule of thumb is that a L<Gnuplot::Builder::Script> object should be a piece of gnuplot script that makes just one plot.
If you want to write anything that doesn't belong to a plot, you should use C<$writer> directly.

For example,

    $builder->multiplot('layout 2,2', sub {
        my $writer = shift;
        my $another_builder = Gnuplot::Builder::Script->new(xrange => q{[-pi:pi]}, title => q{"1. sin(x)"});
        $another_builder->plot("sin(x)");
        $writer->("set multiplot next\n");
        $another_builder->new_child()->set(title => q{"2. sin(2x)"})->plot("sin(2 * x)");
    });

The above example uses a L<Gnuplot::Builder::Script> object and its child to make two plots, while it uses C<$writer> to write "set multiplot next" command.
The "set multiplot next" command is not part of a plot, but it controls the layout of plots.
So we should use C<$writer> to write it.

=head2 $result = $builder->multiplot_with(%args)

Multiplot with more functionalities than C<multiplot()> method.

Fields in C<%args> are

=over

=item C<do> => CODE-REF (mandatory)

A code-ref that is executed in the multiplot context.

=item C<option> => OPTION_STR (optional, default: "")

An option string for "set multiplot" command.

=item C<no_stderr> => BOOL (optional, default: C<$Gnuplot::Builder::Process::NO_STDERR>)

If set to true, the return value C<$result> contains STDOUT only. It doesn't contain gnuplot's STDERR.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=item C<output> => OUTPUT_FILENAME (optional)

If set, "set output" command is printed just before "set multiplot" command.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=item C<writer> => CODE-REF (optional)

A code-ref to receive the whole script string.
If set, the return value C<$result> will be an empty string.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=item C<async> => BOOL (optional, default: C<$Gnuplot::Builder::Process::ASYNC>)

If set to true, it won't wait for the gnuplot process to finish.
In this case, the return value C<$result> will be an empty string.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=back

    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(mxtics => 5, mytics => 5, term => "png");
    
    my $script = "";
    $builder->multiplot_with(
        output => "multi.png",
        writer => sub { $script .= $_[0] },
        option => 'title "multiplot test" layout 2,1',
        do => sub {
            my $another_builder = Gnuplot::Builder::Script->new;
            $another_builder->setq(title => "sin")->plot("sin(x)");
            $aonther_builder->setq(title => "cos")->plot("cos(x)");
        }
    );
    
    $script;
    ## => set mxtics 5
    ## => set mytics 5
    ## => set term png
    ## => set output 'multi.png'
    ## => set multiplot title "multiplot test" layout 2,1
    ## => set title 'sin'
    ## => plot sin(x)
    ## => set title 'cos'
    ## => plot cos(x)
    ## => unset multiplot
    ## => set output

=head2 $result = $builder->run($command, ...)

Build the script, input the script into a new gnuplot process
and input the C<$command>s to the process as well.
This method lets a gnuplot process do the actual job.

C<run()> method is a low-level method of C<plot()>, C<splot()>, C<multiplot()> etc.
You should use other plotting methods if possible.

C<$command> is either a string or a code-ref.
You can specify more than one C<$command>s, which are executed sequentially.

=over

=item *

If C<$command> is a string, it is input to the process as a gnuplot sentence.

=item *

If C<$command> is a code-ref, it is immediately called like

    $command->($writer)

where C<$writer> is a code-ref that you can call to write any data to the gnuplot process.

=back

The return value C<$result> is the data that the gnuplot process writes to STDOUT and STDERR (by default).

C<run()> method is useful when you want to execute "plot" command more than once in a single gnuplot process.
For example,

    my $builder = Gnuplot::Builder::Script->new(<<SET);
    term = gif size 500,500 animate
    output = "waves.gif"
    SET
    
    my $FRAME_NUM = 10;
    $builder->run(sub {
        my $writer = shift;
        foreach my $phase_index (0 .. ($FRAME_NUM-1)) {
            my $phase_deg = 360.0 * $phase_index / $FRAME_NUM;
            $writer->("plot sin(x + $phase_deg / 180.0 * pi)\n");
        }
    });

The above example generates an animated GIF of a traveling sin wave.

Like the C<$code> argument for C<multiplot()> method,
if you call plotting methods (including C<run()> itself) without explicit writer inside C<$command> code block,
those methods won't start a new gnuplot process.
Instead they write the script to the C<$writer> given by the enclosing C<run()> method.

So you can rewrite the C<run()> method of the above example to

    $builder->run(sub {
        my $another_builder = Gnuplot::Builder::Script->new;
        foreach my $phase_index (0 .. ($FRAME_NUM-1)) {
            my $phase_deg = 360.0 * $phase_index / $FRAME_NUM;
            $another_builder->plot("sin(x + $phase_deg / 180.0 * pi)");
        }
    });


C<run()> method may also be useful if you want to enclose some sentences with pairs of sentences.
For example,

    $builder->run(
        "set multiplot layout 2,2",
        "do for [name in  'A B C D'] {",
        sub {
            my $another_builder = Gnuplot::Builder::Script->new;
            $another_builder->define(filename => "name . '.dat'");
            $another_builder->plot('filename u 1:2');
        },
        "}",
        "unset multiplot"
    );

Well, maybe this is not a good example, though. In this case I would rather use C<multiplot()> and iteration in Perl.
There is more than one way to do it.


=head2 $result = $builder->run_with(%args)

Run the script with more functionalities than C<run()> method.

=over

=item C<do> => COMMANDS (optional)

A command or an array-ref of commands to be executed.
See C<run()> for specification of commands.

=item C<output> => OUTPUT_FILENAME (optional)

If set, "set output" command is printed just before running commands.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=item C<no_stderr> => BOOL (optional, default: C<$Gnuplot::Builder::Process::NO_STDERR>)

If set to true, the return value C<$result> contains STDOUT only. It doesn't contain gnuplot's STDERR.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=item C<writer> => CODE-REF (optional)

A code-ref to receive the whole script string. If set, the return value C<$result> will be an empty string.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=item C<async> => BOOL (optional, default: C<$Gnuplot::Builder::Process::ASYNC>)

If set to true, it won't wait for the gnuplot process to finish. In this case, the return value C<$result> will be an empty string.

See L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method for detail.

=back

    my $builder = Gnuplot::Builder::Script->new;
    my $script = "";
    
    $builder->run_with(
        writer => sub { $script .= $_[0] },
        do => [
            "cd 'subdir1'",
            sub {
                foreach my $name (qw(a b c d)) {
                    $builder->plot("'$name.dat' u 1:2 title '$name'");
                }
            }
        ]
    );
    
    $script;
    ## => cd 'subdir1'
    ## => plot 'a.dat' u 1:2 title 'a'
    ## => plot 'b.dat' u 1:2 title 'b'
    ## => plot 'c.dat' u 1:2 title 'c'
    ## => plot 'd.dat' u 1:2 title 'd'

=head1 OBJECT METHODS - PLOTTING OPTIONS

B<< Methods in this section are currently experimental. >>

As you can see in L<"OBJECT METHODS - PLOTTING">,
C<plot_with()>, C<splot_with()>, C<multiplot_with()> and C<run_with()> methods
share some arguments.
With the methods listed in this section, you can store default values for these arguments in a C<$builder> instance.

You can store default values for the following plotting options:

=over

=item C<output> => OUTPUT_FILENAME

=item C<no_stderr> => BOOL

=item C<writer> => CODE-REF

=item C<async> => BOOL

=back

For detail about these arguments, see L<< C<plot_with()>|"$result = $builder->plot_with(%args)" >> method.

Note that those default values also affect the behavior of short-hand methods, i.e. C<plot()>, C<splot()>, C<multiplot()> and C<run()>.

The default values stored in a C<$builder> are used when the correponding arguments are not passed to the plotting methods.
In other words, arguments directly passed to the plotting methods have precedence over the per-instance default values.

The plotting options stored in a C<$builder> is inheritable, just like the "set" and "define" options.

=head2 $builder = $builder->set_plot($arg_name => $arg_value, ...)

Set the plotting option C<$arg_name> to C<$arg_value>.
C<$arg_name> must be one of the plotting options listed above.
You can set more than one C<< $arg_name => $arg_value >> pairs.

    $builder->set_plot(
        output => "hoge.png",
        async => 1
    );
    
    $builder->plot('sin(x)');
    ## Same as:
    ##   $builder->plot_with(
    ##       dataset => 'sin(x)',
    ##       output => "hoge.png",
    ##       async => 1
    ##   );
    
    $builder->plot_with(
        dataset => 'cos(x)',
        output => 'foobar.png'
    );
    ## Same as:
    ##   $builder->plot_with(
    ##       dataset => 'cos(x)',
    ##       output => 'foobar.png',
    ##       async => 1
    ##   );

=head2 $arg_value = $builder->get_plot($arg_name)

Get the value for C<$arg_name>.

If C<$arg_name> is not set in C<$builder>, it returns the value set in its parent builder.
If none of the ancestors have C<$arg_name>, it returns C<undef>.

=head2 $builder = $builder->delete_plot($arg_name, ...)

Delete the default value for C<$arg_name>. You can specify more than one C<$arg_name>s.

=head1 OBJECT METHODS - INHERITANCE

A L<Gnuplot::Builder::Script> object can extend and/or override another
L<Gnuplot::Builder::Script> object.
This is similar to JavaScript's prototype-based inheritance.

Let C<$parent> and C<$child> be the parent and its child builder, respectively.
Then C<$child> builds a script on top of what C<$parent> builds.
That is,

=over

=item *

Sentences added by C<< $child->add() >> method are appended to the C<$parent>'s script.

=item *

Option settings and definitions in C<$child> are appended to the C<$parent>'s script,
if they are not set in C<$parent>.

=item *

Option settings and definitions in C<$child> are substituted in the C<$parent>'s script,
if they are already set in C<$parent>.

=back

A simlar rule is applied to plotting options.
Plotting options in C<$child> are used if those options are set in C<$child>.
Otherwise, plotting options in C<$parent> are used.



=head2 $builder = $builder->set_parent($parent_builder)

Set C<$parent_builder> as the C<$builder>'s parent.

If C<$parent_builder> is C<undef>, C<$builder> doesn't have a parent anymore.

=head2 $parent_builder = $builder->get_parent()

Return the C<$builder>'s parent. It returns C<undef> if C<$builder> does not have a parent.

=head2 $child_builder = $builder->new_child()

Create and return a new child builder of C<$builder>.

This is a short-cut for C<< Gnuplot::Builder::Script->new->set_parent($builder) >>.


=head1 OVERLOAD

When you evaluate a C<$builder> as a string, it executes C<< $builder->to_string() >>. That is,

    "$builder" eq $builder->to_string;

=head1 Data::Focus COMPATIBLITY

L<Gnuplot::Builder::Script> implements C<Lens()> method, so you can use L<Data::Focus> to access its attributes.

The C<Lens()> method creates a L<Data::Focus::Lens> object for accessing gnuplot options via C<get_option()> and C<set_option()>.

Note that the lens calls C<get_option()> always in scalar context.

    use Data::Focus qw(focus);
    
    my $scalar = focus($builder)->get("xrange");
    ## same as: my $scalar = scalar($builder->get_option("xrange"));
        
    my @list = focus($builder)->list("style");
    ## same as: my @list = scalar($builder->get_option("style"));
        
    focus($builder)->set(xrange => '[10:100]');
    ## same as: $builder->set_option(xrange => '[10:100]');

This results in a surprising behavior if you pass array-refs to C<set()> method. Use with care.

=head1 SEE ALSO

L<Gnuplot::Builder::Dataset>

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
