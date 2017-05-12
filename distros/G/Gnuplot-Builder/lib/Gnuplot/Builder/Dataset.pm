package Gnuplot::Builder::Dataset;
use strict;
use warnings;
use Gnuplot::Builder::PrototypedData;
use Scalar::Util qw(weaken blessed);
use Carp;
use overload '""' => 'to_string';

sub new {
    my ($class, $source, @set_option_args) = @_;
    my $self = bless {
        pdata => undef,
        pdata_join => undef,  ## deprecated. should be removed in the future.
        parent => undef,
    }, $class;
    $self->_init_pdata();
    if(defined $source) {
        $self->set_source($source);
    }
    if(@set_option_args) {
        $self->set_option(@set_option_args);
    }
    return $self;
}

sub new_file {
    my ($class, $filename, @set_option_args) = @_;
    return $class->new->set_file($filename)->set_option(@set_option_args);
}

sub new_data {
    my ($class, $data_provider, @set_option_args) = @_;
    return $class->new->set_file('-')->set_data($data_provider)->set_option(@set_option_args);
}

sub _init_pdata {
    my ($self) = @_;
    weaken $self;
    $self->{pdata} = Gnuplot::Builder::PrototypedData->new(
        entry_evaluator => sub {
            my ($key, $coderef) = @_;
            return $coderef->($self, $key);
        },
        attribute_evaluator => { source => sub {
            my ($key, $coderef) = @_;
            return $coderef->($self);
        } },
    );
    $self->{pdata_join} = Gnuplot::Builder::PrototypedData->new();
}

sub to_string {
    my ($self) = @_;
    my @words = ();
    push @words, $self->get_source;
    $self->{pdata}->each_resolved_entry(sub {
        my ($name, $values_arrayref) = @_;
        my @values = grep { defined($_) } @$values_arrayref;
        return if !@values;
        my $join = $self->{pdata_join}->get_resolved_attribute($name);
        if(defined $join) {
            push @words, $name, join($join, @values);
        }else {
            push @words, $name, @values;
        }
    });
    return join " ", grep { defined($_) && "$_" ne "" } @words;
}

*params_string = *to_string;

sub set_source {
    my ($self, $source) = @_;
    $self->{pdata}->set_attribute(
        key => "source", value => $source
    );
    return $self;
}

sub setq_source {
    my ($self, $source) = @_;
    $self->{pdata}->set_attribute(
        key => "source", value => $source, quote => 1,
    );
    return $self;
}

*set_file = *setq_source;

sub get_source {
    my ($self) = @_;
    return $self->{pdata}->get_resolved_attribute("source");
}

sub delete_source {
    my ($self) = @_;
    $self->{pdata}->delete_attribute("source");
    return $self;
}

sub set_option {
    my ($self, @options) = @_;
    $self->{pdata}->set_entry(
        entries => \@options,
        quote => 0,
    );
    return $self;
}

*set = *set_option;

sub setq_option {
    my ($self, @options) = @_;
    $self->{pdata}->set_entry(
        entries => \@options,
        quote => 1,
    );
    return $self;
}

*setq = *setq_option;

sub unset {
    my ($self, @opt_names) = @_;
    return $self->set_option(map {$_ => undef} @opt_names);
}

sub get_option {
    my ($self, $name) = @_;
    return $self->{pdata}->get_resolved_entry($name);
}

sub delete_option {
    my ($self, @names) = @_;
    foreach my $name (@names) {
        $self->{pdata}->delete_entry($name);
    }
    return $self;
}

sub set_parent {
    my ($self, $parent) = @_;
    if(!defined($parent)) {
        $self->{parent} = undef;
        $self->{pdata}->set_parent(undef);
        $self->{pdata_join}->set_parent(undef);
        return $self;
    }
    if(!blessed($parent) || !$parent->isa("Gnuplot::Builder::Dataset")) {
        croak "parent must be a Gnuplot::Builder::Dataset";
    }
    $self->{parent} = $parent;
    $self->{pdata}->set_parent($parent->{pdata});
    $self->{pdata_join}->set_parent($parent->{pdata_join});
    return $self;
}

sub get_parent { return $_[0]->{parent} }

*parent = *get_parent;

sub new_child {
    my ($self) = @_;
    return Gnuplot::Builder::Dataset->new->set_parent($self);
}

sub set_data {
    my ($self, $data_provider) = @_;
    $self->{pdata}->set_attribute(
        key => "data", value => $data_provider
    );
    return $self;
}

sub write_data_to {
    my ($self, $writer) = @_;
    my $data_provider = $self->{pdata}->get_resolved_attribute("data");
    return $self if not defined $data_provider;
    if(ref($data_provider) eq "CODE") {
        $data_provider->($self, $writer);
    }else {
        $writer->($data_provider);
    }
    return $self;
}

sub delete_data {
    my ($self) = @_;
    $self->{pdata}->delete_attribute("data");
    return $self;
}

sub _deprecated {
    my ($msg) = @_;
    my $method = (caller(1))[3];
    carp "$method is deprecated. $msg";
}

sub set_join {
    my ($self, %joins) = @_;
    _deprecated("Use Gnuplot::Builder::JoinDict.");
    foreach my $name (keys %joins) {
        $self->{pdata_join}->set_attribute(
            key => $name, value => $joins{$name}, quote => 0
        );
    }
    return $self;
}

sub delete_join {
    my ($self, @names) = @_;
    _deprecated("Use Gnuplot::Builder::JoinDict.");
    foreach my $name (@names) {
        $self->{pdata_join}->delete_attribute($name);
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

Gnuplot::Builder::Dataset - object-oriented builder for gnuplot dataset

=head1 SYNOPSIS

    use Gnuplot::Builder::Script;
    use Gnuplot::Builder::Dataset;
        
    my $builder = Gnuplot::Builder::Script->new;
    
    my $func_data = Gnuplot::Builder::Dataset->new('sin(x)');
    $func_data->set(title => '"function"', with => "lines");
        
    my $unit_scale = 0.001;
    my $file_data = Gnuplot::Builder::Dataset->new_file("sampled_data1.dat");
    $file_data->set(
        using => sub { "1:(\$2 * $unit_scale)" },
        title => '"sample 1"',
        with  => 'linespoints lw 2'
    );
        
    my $another_file_data = $file_data->new_child;
    $another_file_data->set_file("sampled_data2.dat");  ## override parent's setting
    $another_file_data->setq(title => "sample 2");      ## override parent's setting
    
    my $inline_data = Gnuplot::Builder::Dataset->new_data(<<INLINE_DATA);
    1.0  3.2
    1.4  3.0
    1.9  4.3
    2.2  3.9
    INLINE_DATA
    $inline_data->set(using => "1:2", title => '"sample 3"');
        
    print $builder->plot($func_data, $file_data, $another_file_data, $inline_data);

=head1 DESCRIPTION

L<Gnuplot::Builder::Dataset> is a builder object for gnuplot dataset (the data to be plotted).

Like L<Gnuplot::Builder::Script>, this module stores dataset parameters in a hash-like structure.
It supports lazy evaluation and prototype-based inheritance, too.

=head2 Data Model

A L<Gnuplot::Builder::Dataset> consists of three attributes; B<< the source, the options and the inline data >>.

    plot "source.dat" using 1:2 title "file" with lp, \
         f(x) title "function" with lines, \
         "-" using 1:2 title "inline" with lp
    10 20
    15 11
    20 43
    25 32
    end

=over

=item *

The source is the first part of the dataset parameters.
In the above example, C<"source.dat">, C<f(x)> and C<"-"> are the sources.

=item *

The options are the rest of the dataset parameters after the source.
In the above example, C<< using 1:2 title "file" with lp >> is the options of the first dataset.
L<Gnuplot::Builder::Dataset> stores the options in a hash-like data structure.

=item *

The inline data is the data given after the "plot" command.
In the above example, only the third dataset has its inline data.

=back

=head2 Complex Dataset Options

Sometimes dataset options can be complex.
For example, have you ever been confused by
L<< the complicated order of "using" option parameters for "candlesticks" plot style |http://gnuplot.sourceforge.net/demo_4.6/candlesticks.html >>? I have!

If you have trouble dealing with those complex options,
check out L<Gnuplot::Builder::Template> and L<Gnuplot::Builder::JoinDict>.
They might help you arrange option values and stuff.


=head1 CLASS METHODS

=head2 $dataset = Gnuplot::Builder::Dataset->new($source, @set_args)

The general-purpose constructor. All arguments are optional.
C<$source> is the source string of this dataset. C<@set_args> are the option settings.

This method is equivalent to C<< new()->set_source($source)->set(@set_args) >>.

=head2 $dataset = Gnuplot::Builder::Dataset->new_file($filename, @set_args)

The constructor for datasets whose source is a file.
C<$filename> is the name of the source file.

This method is equivalent to C<< new()->set_file($filename)->set(@set_args) >>.

=head2 $dataset = Gnuplot::Builder::Dataset->new_data($data_provider, @set_args)

The constructor for datasets that have inline data.
C<$data_provider> is the inline data or a code-ref that provides it.

This method is equivalent to C<< new()->set_file('-')->set_data($data_provider)->set(@set_args) >>.

=head1 OBJECT METHODS - BASICS

=head2 $string = $dataset->to_string()

Build and return the dataset parameter string.
It does not contain the inline data.

=head2 $string = $dataset->params_string()

Alias of C<to_string()> method. It's for plotting methods of L<Gnuplot::Builder::Script>.

=head1 OBJECT METHODS - SOURCE

Methods about the source of the dataset.

=head2 $dataset = $dataset->set_source($source)

Set the source of the C<$dataset> to C<$source>.

C<$source> is either a string or code-ref.
If C<$source> is a string, that string is used for the source.

If C<$source> is a code-ref, it is evaluated in list context when C<$dataset> builds the parameters.

    ($source_str) = $source->($dataset)

C<$dataset> is passed to the code-ref.
The first element of the result (C<$source_str>) is used for the source.

=head2 $dataset = $dataset->setq_source($source)

Same as C<set_source()> method except that the eventual source string is quoted.
Useful for setting the file name of the dataset.

    my $file_index = 5;
    $dataset->setq_source(sub { qq{file_$file_index.dat} });
    $dataset->to_string();
    ## => 'file_5.dat'

=head2 $dataset = $dataset->set_file($source_filename)

Alias of C<setq_source()> method.

=head2 $source_str = $dataset->get_source()

Return the source string of the C<$dataset>.

If a code-ref is set for the source, it is evaluated and the result is returned.

If the source is not set in the C<$dataset>, it returns its parent's source string.
If none of the ancestors doesn't have the source, it returns C<undef>.

=head2 $dataset = $dataset->delete_source()

Delete the source setting from the C<$dataset>.

After the source is deleted, C<get_source()> method will search the parent for the source string.

=head1 OBJECT METHODS - OPTIONS

Methods about the options of the dataset.

These methods are very similar to the methods of the same names in L<Gnuplot::Builder::Script>.

=head2 $dataset = $dataset->set($opt_name => $opt_value, ...)

Set the dataset option named C<$opt_name> to C<$opt_value>.
You can specify more than one pairs of C<$opt_name> and C<$opt_value>.

C<$opt_name> is the name of the option (e.g. "using" and "every").

C<$opt_value> is either C<undef>, a string, an array-ref of strings, a code-ref or a blessed object.

=over

=item *

If C<$opt_value> is C<undef>, the whole option (including the name) won't appear in the parameters it builds.

=item *

If C<$opt_value> is a string, the option is set to that string.

=item *

If C<$opt_value> is an array-ref, the elements in the array-ref will be concatenated with spaces when it builds the parameters.
If the array-ref is empty, the whole option (including the name) won't appear in the parameters.

    $dataset->set(
        binary => ['record=356:356:356', 'skip=512:256:256']
    );
    $dataset->to_string;
    ## => 'hoge' binary record=356:356:356 skip=512:256:256

=item *

If C<$opt_value> is a code-ref, that is evaluated in list context when the C<$dataset> builds the parameters.

    @returned_values = $opt_value->($dataset, $opt_name)

C<$dataset> and C<$opt_name> are passed to the code-ref.

Then, the option is generated as if C<< $opt_name => \@returned_values >> was set.
You can return an C<undef> or an empty list to disable the option.

=item *

If C<$opt_value> is a blessed object, it's stringification (i.e. C<< "$opt_value" >>) is evaluated when C<$dataset> builds the parameters.
You can retrieve the object by C<get_option()> method.


=back

The options are stored in a hash-like structure, so you can change them individually.

Even if you change an option value, its order is unchanged.

    my $scale = 0.001;
    $dataset->set_file('dataset.csv');
    $dataset->set(
        every => undef,
        using => sub { qq{1:(\$2*$scale)} },
        title => '"data"',
        with  => 'lines lw 2'
    );
    $dataset->to_string();
    ## => 'dataset.csv' using 1:($2*0.001) title "data" with lines lw 2
    
    $dataset->set(
        title => undef,
        every => '::1',
    );
    $dataset->to_string();
    ## => 'dataset.csv' every ::1 using 1:($2*0.001) with lines lw 2

You are free to pass any string to C<$opt_name> in any order,
but this module does not guarantee it's syntactically correct.

    $bad_dataset->set(
        lw => 4,
        w  => "lp",
        ps => "variable",
        u  => "1:2:3"
    );
    $bad_dataset->to_string();
    ## => 'hoge' lw 4 w lp ps variable u 1:2:3
    
    ## The above parameters are invalid!!!
    
    $good_dataset->set(
        u  => "1:2:3",
        w  => "lp",
        lw => 4,
        ps => "variable"
    );
    $good_dataset->to_string();
    ## => 'hoge' u 1:2:3 w lp lw 4 ps variable


Some dataset options such as "matrix" and "volatile" don't have arguments.
You can set such options like this.

    $dataset->set(
        matrix   => "",    ## enable
        volatile => undef, ## disable
    );

Or, you can even write like this.

    $dataset->set(
        "" => "matrix"
    );

There is more than one way to do it.

=head2 $dataset = $dataset->set($options)

If C<set()> method is called with a single string argument C<$options>,
it is parsed to set options.

    $dataset->set(<<END_OPTIONS);
    using = 1:3
    -axes
    title = "Weight [kg]"
    with  = lines
    lw    = 2
    END_OPTIONS

The parsing rule is more or less the same as C<set()> method of L<Gnuplot::Builder::Script>.
Here is the overview.

=over

=item *

Options are set like

    OPT_NAME = OPT_VALUE

=item *

If OPT_VALUE is an empty string, you can omit "=".

=item *

Options can be explicitly disabled by the leading "-" like

    -OPT_NAME

=item *

If the same OPT_NAME is repeated with different OPT_VALUEs,
it's equivalent to C<< set($opt_name => [$opt_value1, $opt_value2, ...]) >>.

=back

=head2 $dataset = $dataset->set_option(...)

C<set_option()> method is alias of C<set()>.

=head2 $dataset = $dataset->setq(...)

Same as C<set()> method except that the eventual option value is quoted.
This is useful for setting "title" and "index".

    $dataset->setq(
        title => "Sample A's result",
    );
    $dataset->to_string();
    ## => "hoge" title 'Sample A''s result'
    
    $dataset->setq(
        title => ""  ## same effect as "notitle"
    );
    $dataset->to_string();
    ## => "hoge" title ''

=head2 $dataset = $dataset->setq_option(...)

C<setq_option()> method is alias of C<setq()>.

=head2 $dataset = $dataset->unset($opt_name ...)

Short-cut for C<< set($opt_name => undef) >>. It disables the dataset option.

You can specify more than one C<$opt_name>s.

=head2 @opt_values = $dataset->get_option($opt_name)

Return the option values for the name C<$opt_name>.
In list context, it returns all values for C<$opt_name>.
In scalar context, it returns only the first value.

If a code-ref is set to the C<$opt_name>, it's evaluated and its results are returned.

If a blessed object is set to the C<$opt_name>, that object is returned.

If the option is not set in C<$dataset>, the value of its parent is returned.
If none of the ancestors doesn't have the option, it returns an empty list in list context
or C<undef> in scalar context.

=head2 $dataset = $dataset->delete_option($opt_name, ...)

Delete the option from the C<$dataset>.
You can specify more than one C<$opt_name>s.

Note the difference between C<delete_option($opt_name)> and C<< set_option($opt_name => undef) >>.
C<delete_option()> removes the option setting from the C<$dataset>,
so it's up to its ancestors to determine the value of the option.
On the other hand, C<set_option()> always overrides the parent's setting.

=head1 OBJECT METHODS - INLINE DATA

Methods about the inline data of the dataset.

=head2 $dataset = $dataset->set_data($data_provider)

Set the inline data of the C<$dataset>.

C<$data_provider> is either C<undef>, a string or a code-ref.

=over

=item *

If C<$data_provider> is C<undef>, it means that C<$dataset> has no inline data.

=item *

If C<$data_provider> is a string, that is the inline data of the C<$dataset>.

    $dataset->set_data(<<INLINE_DATA);
    1 10
    2 20
    3 30
    INLINE_DATA

=item *

If C<$data_provider> is a code-ref, it is called in void context when C<$dataset> needs the inline data.

    $data_provider->($dataset, $writer)

C<$dataset> is passed as the first argument to the code-ref.
The second argument (C<$writer>) is a code-ref that you have to call to write inline data.

    $dataset->set_data(sub {
        my ($dataset, $writer) = @_;
        foreach my $x (1 .. 3) {
            my $y = $x * 10;
            $writer->("$x $y\n");
        }
    });

This allows for very large inline data streaming directly into the gnuplot process.

If you don't pass any data to C<$writer>, it means the C<$dataset> doesn't have inline data at all.

=back

=head2 $dataset = $dataset->write_data_to($writer)

Write the inline data using the C<$writer>.
This method is required by plotting methods of L<Gnuplot::Builder::Script>.

C<$writer> is a code-ref that is called by the C<$dataset> to write inline data.
C<$writer> can be called zero or more times.

    my $inline_data = "";
    $dataset->write_data_to(sub {
        my ($data_part) = @_;
        $inline_data .= $data_part;
    });

If C<$dataset> doesn't have inline data setting,
it's up to C<$dataset>'s ancestors to write the inline data.
If none of them have inline data, C<$writer> is not called at all.

=head2 $dataset = $dataset->delete_data()

Delete the inline data setting from the C<$dataset>.

=head1 OBJECT METHODS - INHERITANCE

L<Gnuplot::Builder::Dataset> supports prototype-based inheritance
just like L<Gnuplot::Builder::Script>.

A child dataset inherits the source, the options and the inline data from its parent.
The child can override them individually, or use the parent's setting as-is.

=head2 $dataset = $dataset->set_parent($parent_dataset)

Set C<$parent_dataset> as the C<$dataset>'s parent.

If C<$parent_dataset> is C<undef>, C<$dataset> doesn't have parent anymore.

=head2 $parent_dataset = $dataset->get_parent()

Return the C<$dataset>'s parent.

If C<$dataset> doesn't have any parent, it returns C<undef>.

=head2 $child_dataset = $dataset->new_child()

Create and return a new child of the C<$dataset>.

This is equivalent to C<< Gnuplot::Builder::Dataset->new->set_parent($dataset) >>.

=head1 OVERLOAD

When you evaluate a C<$dataset> as a string, it executes C<< $dataset->to_string() >>. That is,

    "$dataset" eq $dataset->to_string;

=head1 Data::Focus COMPATIBLITY

L<Gnuplot::Builder::Dataset> implements C<Lens()> method, so you can use L<Data::Focus> to access its attributes.

The C<Lens()> method creates a L<Data::Focus::Lens> object for accessing dataset options via C<get_option()> and C<set_option()>.

Note that the lens calls C<get_option()> always in scalar context, just like the lens for L<Gnuplot::Builder::Script>.

=head1 SEE ALSO

L<Gnuplot::Builder::Script>

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
