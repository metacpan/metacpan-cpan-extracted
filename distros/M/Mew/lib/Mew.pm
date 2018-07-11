package Mew;

use strictures 2;

our $VERSION = '1.002001'; # VERSION

use Import::Into;
use Moo;

sub import {
    my $class = shift;
    strictures->import::into(1);
    Moo->import::into(1);
    MooX->import::into(1, $_) for @_;
    MooX::ChainedAttributes->import::into(1);
    Types::Standard->import::into(1, qw/:all/);
    Types::Common::Numeric->import::into(1, qw/:all/);

    my $target = caller;
    my $moo_has = $target->can('has');
    Moo::_install_tracked $target => has => sub {
        my $name_proto = shift;
        my @name_proto = ref $name_proto eq 'ARRAY'
            ? @$name_proto : $name_proto;

        my $req = 1;
        my $mew_type;
        $mew_type = shift if @_ % 2 != 0;
        if ($mew_type and $mew_type->is_parameterized and $mew_type->parent == Types::Standard::Optional()) {
            $req = 0;
            $mew_type = $mew_type->type_parameter;
        }
        elsif ($mew_type and $mew_type == Types::Standard::Optional()) {
            $req = 0;
            $mew_type = Types::Standard::Any();
        }
        for my $attr ( @name_proto ) {
            my %spec = @_;
            if ( $mew_type ) {
                my %mew_spec;
                $mew_spec{required} = $req unless $attr =~ s/^-//;
                ( $mew_spec{init_arg} = $attr ) =~ s/^_//
                    unless exists $spec{init_arg};

                %spec = (
                    is  => $spec{chained} ? 'rw' : 'ro' ,
                    isa => $mew_type,
                    %mew_spec,
                    %spec,
                );
            }
            $moo_has->( $attr => %spec );
        }

        return;
    };

    namespace::clean->import::into(1);
}

q|
    To err is human -- and to blame it on a computer is even more so
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix Altreus copypasta mst

=head1 NAME

Mew - Moo with sugar on top

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    #
    # This:
    #
    use Mew;

    has  _foo  => PositiveNum;
    has -_bar  => Bool;  # note the minus: it means attribute is not `required`
    has  type  => ( Str, default => 'html', chained => 1); # fluent interface
    has  _cust => ( is => 'ro', isa => sub{ 42 } );        # standard Moo `has`
    has [qw/_ar1  -_ar2/] => Str;                          # Multiple args

    #
    # Is the same as:
    #
    use strictures 2;
    use Types::Standard qw/:all/;
    use Types::Common::Numeric qw/:all/;
    use Moo;
    use MooX::ChainedAttributes;
    use namespace::clean;

    has _foo  => (
        init_arg => 'foo',
        is       => 'ro'
        isa      => PositiveNum,
        required => 1,
    );

    has _bar  => (
        init_arg => 'bar',
        is       => 'ro'
        isa      => Bool,
    );

    has type  => (
        chained  => 1,
        is       => 'rw'
        isa      => Str,
        default  => 'html',
    );

    has _cust => (
        is  => 'ro',
        isa => sub{ 42 },
    );

    has _ar1  => (
        init_arg => 'ar1',
        is       => 'ro'
        isa      => Str,
        required => 1,
    );

    has ar2  => (
        init_arg => 'ar2',
        is       => 'ro'
        isa      => Str,
    );


=for html  </div></div>

=head1 DESCRIPTION

This module is just like regular L<Moo>, except it also imports
L<strictures> and L<namespace::clean>, along with
a couple of standard types modules. In addition, it sweetens the
L<Moo's has subroutine|Moo/has> to allow for more concise attribute
declarations.

=head1 READ FIRST

Virtually all of the functionality is described in L<Moo>.

=head1 IMPORTED MODULES

    use Mew;

Automatically imports the following modules: L<Moo>, L<strictures>,
L<Types::Standard>, L<Types::Common::Numeric>, L<MooX::ChainedAttributes>,
and L<namespace::clean>. B<NOTE: in particular the last one.> It'll scrub
your namespace, thus if you're using things like L<experimental>, you should
declare them B<after> you C<use Mew>.

=head1 C<has> SUGAR

=head2 Call it like if it were Moo

    has _cust => ( is => 'ro' );

First, you can call C<has> just like you'd call L<Moo/has> and it'll work
exactly as it used to. The sugar won't be enabled in that case.

=head2 Specify C<isa> type to get sugar

    has _cust => Str;
    has _cust => ( Str, default => "foo" ); # Note: can't use "=>" after Str
    has [qw/_z1  -z2/] => Str;

To get the sugar, you need to specify one of the imported types from either
L<Types::Standard> or L<Types::Common::Numeric> as the second argument. Once
that is done, C<Mew> will add some default settings, which are:

    1) Set `isa` to the type you gave
    2) Set `is` to 'ro' (or 'rw', if `chained` is set)
    3) Set `require` to 1
    4) Set `init_arg` to the name of the attribute, removing
        the leading underscore, if it's present

Thus, C<< has _cust => Str; >> is equivalent to

    use Types::Standard qw/Str/;
    has _cust => (
        init_arg => 'cust',
        is       => 'ro'
        isa      => Str,
        required => 1,
    );

You can specify same settings for multiple attributes by providing
their names in an arrayref:

    has [qw/_z1  -z2/] => Str;

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

B<IMPORTANT NOTE:> because Perl's fat comma (C<< => >>) quotes the argument
on the left side, using it after the type won't work:

    has _cust => Str => ( default => "BROKEN" ); # WRONG!!!!
    has _cust => Str, ( default => "WORKS" ); # Correct!
    has _cust => ( Str, default => "WORKS" ); # This is fine too

=for html  </div></div>

=head2 Method chaining

    package Foo;
    use Mew;
    has cost   => ( PostiveNum, chained => 1 );
    has weight => ( PostiveNum, chained => 1 );
    has size   => ( Str,        chained => 1 );

    ...

    my $object = Foo->new->cost( 42 )->weight( 45 )->size("X-Large");
    say $object->size; # prints "X-Large"

To have L<fluent interface|https://en.wikipedia.org/wiki/Fluent_interface>
or allow "chaining" your attributes, simply add C<< chained => 1 >> option
to your attribute declaration. B<Note:> this will automatically use
C<rw> instead of C<ro> for the default of the C<is> option.

=head3 Modify the sugar

It's possible to alter the defaults created by C<Mew>:

=head4 Remove C<required>

    has -_cust => Str;

Simply prefix the attribute's name with a minus sign to avoid setting
C<< required => 1 >>.

Alternatively, use the C<Optional> type provided by Types::Standard.

    has _cust => Optional[Str];

=head4 Modify other options

    has  _cust => Str, ( init arg => "bar" );
    has -_cust => Str, ( is => "lazy" );

You can explicitly provide values for options set by C<Mew>, in which case
the values you provide will be used instead of the defaults.

=head1 SEE ALSO

L<Moo>, L<Type::Tiny>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Mew>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Mew/issues>

If you can't access GitHub, you can email your request
to C<bug-Mew at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

Part of the code was borrowed from L<Moo>'s innards. L<ew> module is an
almost-verbatim copy of L<oo> module. Thanks to I<Matt S. Trout (mst)> for
changing my copypasta of Moo's internals to sane code and other help.
Props to I<Altreus> for coming up with the name for the module.

The rest is:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for html  </div></div>

=head1 CONTRIBUTORS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/MSTROUT"> <img src="http://www.gravatar.com/avatar/9a085716bde55f2144dcb29eee47cead?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F4e8e2db385219e064e6dea8fbd386434" alt="MSTROUT" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">MSTROUT</span> </a> </span>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut