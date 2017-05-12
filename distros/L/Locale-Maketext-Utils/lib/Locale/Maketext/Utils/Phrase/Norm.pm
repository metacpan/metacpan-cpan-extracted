package Locale::Maketext::Utils::Phrase::Norm;

use strict;
use warnings;

$Locale::Maketext::Utils::Phrase::Norm::VERSION = '0.2';

use Module::Want ();
use Carp         ();

# IF YOU CHANGE THIS CHANGE THE “DEFAULT FILTERS” POD SECTION ALSO
my @default_filters = qw(NonBytesStr WhiteSpace Grapheme Ampersand Markup Ellipsis BeginUpper EndPunc Consider Escapes Compiles);    # IF YOU CHANGE THIS CHANGE THE “DEFAULT FILTERS” POD SECTION ALSO

# IF YOU CHANGE THIS CHANGE THE “DEFAULT FILTERS” POD SECTION ALSO

# TODO ?: Acronym, IntroComma, Parens (needs CLDR char/pattern in Locales.pm) [output,chr,(not|in|the|markup|list|or any if amp() etc happen )???

sub new_target {
    my $conf = ref( $_[-1] ) eq 'HASH' ? pop(@_) : {};

    # IF YOU CHANGE THIS CHANGE THE “new_target()” POD SECTION ALSO
    $conf->{'exclude_filters'}{'BeginUpper'} = 1;    # IF YOU CHANGE THIS CHANGE THE “new_target()” POD SECTION ALSO
    $conf->{'exclude_filters'}{'EndPunc'}    = 1;    # IF YOU CHANGE THIS CHANGE THE “new_target()” POD SECTION ALSO

    # IF YOU CHANGE THIS CHANGE THE “new_target()” POD SECTION ALSO

    push @_, $conf;
    goto &new_source;
}

sub new {
    Carp::carp('new() is deprecated, use new_source() instead');
    goto &new_source;
}

sub new_source {
    my $ns = shift;
    $ns = ref($ns) if ref($ns);    # just the class ma'am

    my $conf = ref( $_[-1] ) eq 'HASH' ? pop(@_) : {};

    my @filters;
    my %cr2ns;
    my $n;                         # buffer
    my @filternames;

    for $n ( $conf->{'skip_defaults_when_given_filters'} ? ( @_ ? @_ : @default_filters ) : ( @default_filters, @_ ) ) {
        my $name = $n =~ m/[:']/ ? $n : __PACKAGE__ . "::$n";

        next if ( exists $conf->{'exclude_filters'}{$n} && $conf->{'exclude_filters'}{$n} ) || ( exists $conf->{'exclude_filters'}{$name} && $conf->{'exclude_filters'}{$name} );

        if ( Module::Want::have_mod($name) ) {
            if ( my $cr = $name->can('normalize_maketext_string') ) {
                push @filters, $cr;
                $cr2ns{"$cr"} = $name;
                push @filternames, $name;
            }
            else {
                Carp::carp("$name does not implement normalize_maketext_string()");
                return;
            }
        }
        else {
            Carp::carp($@);
            return;
        }
    }

    if ( !@filters ) {
        Carp::carp("Filter list is empty!");
        return;
    }

    my $run_extra_filters = exists $conf->{'run_extra_filters'} ? ( $conf->{'run_extra_filters'} ? 1 : 0 ) : 0;

    my $new_obj = bless {
        'filters'           => \@filters,
        'cache'             => {},
        'filter_namespace'  => \%cr2ns,
        'filternames'       => \@filternames,
        'run_extra_filters' => $run_extra_filters,
        'maketext_object'   => undef,
    }, $ns;

    if ( exists $conf->{'maketext_object'} ) {
        $new_obj->set_maketext_object( $conf->{'maketext_object'} ) || return;
    }

    return $new_obj;
}

sub set_maketext_object {
    my ( $self, $mt_obj ) = @_;
    if ( ref($mt_obj) ) {
        if ( $mt_obj->can('makethis') ) {
            $self->delete_cache();
            $self->{'maketext_object'} = $mt_obj;
        }
        else {
            Carp::carp('Given maketext object does not have a makethis() method.');
            return;
        }
    }
    else {
        Carp::carp('Given maketext object is not a reference.');
        return;
    }

    return $self->{'maketext_object'};
}

sub get_maketext_object {
    return $_[0]->{'maketext_object'} if defined $_[0]->{'maketext_object'};

    # Do not delete cache since filters clas call this mid stream

    require Locale::Maketext::Utils::Mock;
    $_[0]->{'maketext_object'} = Locale::Maketext::Utils::Mock->get_handle();    # We can't do a class or else we get this sort of thing: Can't use string ("Locale::Maketext::Utils") as a HASH ref while "strict refs" in use at …/Locale/Maketext.pm line N.

    return $_[0]->{'maketext_object'};
}

sub enable_extra_filters {
    $_[0]->delete_cache();
    $_[0]->{'run_extra_filters'} = 1;
}

sub disable_extra_filters {
    $_[0]->delete_cache();
    $_[0]->{'run_extra_filters'} = 0;
}

sub run_extra_filters {
    return 1 if $_[0]->{'run_extra_filters'};
    return;
}

sub delete_cache {
    delete $_[0]->{'cache'};
}

sub normalize {
    my ( $self, $string ) = @_;

    if ( !defined $string ) {
        Carp::carp('You must pass a value to normalize()');
        return;
    }

    return $self->{'cache'}{$string} if exists $self->{'cache'}{$string};

    $self->{'cache'}{$string} = bless {
        'status'           => 1,
        'warning_count'    => 0,
        'violation_count'  => 0,
        'filter_results'   => [],
        'orig_str'         => $string,
        'aggregate_result' => $string,
      },
      'Locale::Maketext::Utils::Phrase::Norm::_Res';

    my $cr;    # buffer
    foreach $cr ( @{ $self->{'filters'} } ) {
        push @{ $self->{'cache'}{$string}{'filter_results'} }, bless {
            'status'     => 1,
            'package'    => $self->{'filter_namespace'}{"$cr"},
            'orig_str'   => $string,
            'new_str'    => $string,
            'violations' => [],                                   # status 0
            'warnings'   => [],                                   # status -1 (true but not 1)
            '_get_mt'    => sub {
                return $self->get_maketext_object();
            },
            '_run_extra' => sub {
                return $self->run_extra_filters();
            },
          },
          'Locale::Maketext::Utils::Phrase::Norm::_Res::Filter';

        my ( $filter_rc, $violation_count, $warning_count, $filter_modifies_string ) = $cr->( $self->{'cache'}{$string}{'filter_results'}[-1] );

        # Update string's overall aggregate modifcation
        if ($filter_modifies_string) {

            # Run aggregate value through filter, not perfect since it isn't operating on the same value as above
            my $agg_filt = bless {
                'status'     => 1,
                'package'    => $self->{'filter_namespace'}{"$cr"},
                'orig_str'   => $self->{'cache'}{$string}{'aggregate_result'},
                'new_str'    => $self->{'cache'}{$string}{'aggregate_result'},
                'violations' => [],                                              # status 0
                'warnings'   => [],                                              # status -1 (true but not 1)
                '_get_mt'    => sub {
                    return $self->get_maketext_object();
                },
                '_run_extra' => sub {
                    return $self->run_extra_filters();
                },
              },
              'Locale::Maketext::Utils::Phrase::Norm::_Res::Filter';

            $cr->($agg_filt);
            $self->{'cache'}{$string}{'aggregate_result'} = $agg_filt->get_new_str();
        }

        # Update string's overall result
        $self->{'cache'}{$string}{'violation_count'} += $violation_count;
        $self->{'cache'}{$string}{'warning_count'}   += $warning_count;
        if ( $self->{'cache'}{$string}->{'status'} ) {
            if ( !$filter_rc ) {
                $self->{'cache'}{$string}{'status'} = $filter_rc;
            }
            elsif ( $self->{'cache'}{$string}->{'status'} != -1 ) {
                $self->{'cache'}{$string}{'status'} = $filter_rc;
            }
        }

        last if !$filter_rc && $self->{'stop_filter_on_error'};    # TODO: document, add POD, methods, new_source(), tests etc.
    }

    return $self->{'cache'}{$string};
}

package Locale::Maketext::Utils::Phrase::Norm::_Res;

sub get_status {
    return $_[0]->{'status'};
}

sub get_warning_count {
    return $_[0]->{'warning_count'};
}

sub get_violation_count {
    return $_[0]->{'violation_count'};
}

sub get_filter_results {
    return $_[0]->{'filter_results'};
}

sub get_orig_str {
    return $_[0]->{'orig_str'};
}

sub get_aggregate_result {
    return $_[0]->{'aggregate_result'} || $_[0]->{'orig_str'};
}

sub filters_modify_string {
    return 1 if $_[0]->{'aggregate_result'} ne $_[0]->{'orig_str'};
    return;
}

package Locale::Maketext::Utils::Phrase::Norm::_Res::Filter;

sub run_extra_filters {
    return $_[0]->{'_run_extra'}->();
}

sub get_maketext_object {
    return $_[0]->{'_get_mt'}->();
}

sub add_violation {
    my ( $self, $error ) = @_;
    $self->{'status'} = 0;
    push @{ $self->{'violations'} }, $error;
}

sub add_warning {
    my ( $self, $warning ) = @_;
    $self->{'status'} = -1 if !$self->get_violations();
    push @{ $self->{'warnings'} }, $warning;
}

sub get_status {
    return $_[0]->{'status'};
}

sub get_package {
    return $_[0]->{'package'};
}

sub get_orig_str {
    return $_[0]->{'orig_str'};
}

sub get_new_str {
    return $_[0]->{'new_str'};
}

sub get_violations {
    return if !@{ $_[0]->{'violations'} };
    return $_[0]->{'violations'};
}

sub get_warnings {
    return if !@{ $_[0]->{'warnings'} };
    return $_[0]->{'warnings'};
}

sub get_string_sr {
    return \$_[0]->{'new_str'};
}

sub get_warning_count {
    return $_[0]->get_warnings() ? scalar( @{ $_[0]->get_warnings() } ) : 0;
}

sub get_violation_count {
    return $_[0]->get_violations() ? scalar( @{ $_[0]->get_violations() } ) : 0;
}

sub return_value {
    my ($self) = @_;
    return ( $self->{'status'}, $self->get_violation_count(), $self->get_warning_count(), $self->filter_modifies_string() );
}

sub return_value_noop {
    return ( 2, 0, 0, 0 );
}

sub filter_modifies_string {
    return 1 if $_[0]->{'orig_str'} ne $_[0]->{'new_str'};
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Locale::Maketext::Utils::Phrase::Norm - Normalize and perform lint-like analysis of phrases

=head1 VERSION

This document describes Locale::Maketext::Utils::Phrase::Norm version 0.2

=head1 SYNOPSIS

    use Locale::Maketext::Utils::Phrase::Norm;

    my $norm = Locale::Maketext::Utils::Phrase::Norm->new_source() || die;

    my $result = $norm->normalize('This office has worked [quant,_1,day,days,zero days] without an “accident”.');

    # process $result

=head1 DESCRIPTION

Analyze, report, and normalize a maketext style phrase based on rules organized into filter modules.

=head1 INTERFACE

=head2 Main object

=head3 new_source()

A “source phrase” is a phrase (suitable for a call to maketext()) in the main locale’s language that we intend to be localizable.

Typically this is the key of a lexicon’s hash but it can be the value if the main locale lexicon’s key is an “Arbitrary Key”, that is, if the value is different from the key in the main locale’s lexicon.

new_source() creates a new object with all the filters initialized for source phrases.

Giving no arguments means it will employ all of the default filter modules (documented in L</"DEFAULT FILTERS">).

Otherwise the optional arguments are:

=over 4

=item A list of filter module name spaces to run after the default filter modules.

If the given module name does not contain any package seperators it will be treated as if it needs prepended with 'Locale::Maketext::Utils::Phrase::Norm::'.

e.g. Given 'Locale::Maketext::Utils::Phrase::Norm::MyCoolFilter' you can pass the name 'MyCoolFilter'.

=item The last argument can be a hashref of options:

    my $norm = Locale::Maketext::Utils::Phrase::Norm->new_source('My::Filter::XYZ'); # all default filters followed by the My::Filter::XYZ filter

    my $norm = Locale::Maketext::Utils::Phrase::Norm->new_source('My::Filter::XYZ', { 'skip_defaults_when_given_filters' => 1 }); # only do My::Filter::XYZ the filter

The options are outlined below and are all optional:

=over 4

=item 'skip_defaults_when_given_filters'

Boolean.

When false (default) your filters are appended to the list of default filters.

When true the default list of filters is not used.

=item 'maketext_object'

An object that can be used by filters should they need one to perform their task. Currently, it must have a makethis() method.

The main object and filter each have a L<get_maketext_object()> method to fetch this when needed.

If you did not specify an argument here L<get_maketext_object()> returns a L<Locale::Maketext::Utils::Mock> object. That means all the cool stuff in your locale object that you might want to use in your filter will not be available.

=item 'run_extra_filters'

Boolean.

When false (default) L</extra filters> are not executed.

When true the L</extra filters> are executed.

=item 'exclude_filters'

A hashref of filters to exclude from the object regardless of the list in effect.

The key can be the long or short name space of the filter modules and the value must be true for the entry to take effect.

=back

=back

new_source() carp()s and returns false if there is some sort of failure (documented in L</"DIAGNOSTICS">).

=head3 new_target()

A “target phrase” is the translated version of a given source phrase. This is the value of a non-main-locale lexicon’s hash.

new_target() is just like new_source() but uses a subset of the L</"DEFAULT FILTERS"> that apply to translations.

Currently the exclusion of L<BeginUpper|Locale::Maketext::Utils::Phrase::Norm::BeginUpper> and L<EndPunc|Locale::Maketext::Utils::Phrase::Norm::EndPunc> from the L</"DEFAULT FILTERS"> is what makes up this object.

=head3 normalize()

Takes a phrase as the only argument and returns a result object (documented in L</"Result Object">).

=head3 delete_cache()

The result of normalize() is cached internally so calling it subsequent times with the same string won’t result in it being reprocessed.

This method deletes the internal cache. Returns the hashref that was removed.

=head3 get_maketext_object()

Returns the object you instantiated the L</"Main object"> with.

If you did not specify an argument a L<Locale::Maketext::Utils::Mock> object is used. That means all the cool stuff in your locale object that you might want to use in your filter will not be available.

=head3 set_maketext_object()

Takes the same object you’d pass to the constructor method via ‘maketext_object’.

This is what will be used on subsequent calls to normalize().

=head3 run_extra_filters()

Boolean return value of if we are running L</extra filters> or not.

=head3 enable_extra_filters()

No arguments, enables the running of any L</extra filters> on subsequent calls to normalize().

=head3 disable_extra_filters()

No arguments, disables the running of any L</extra filters> on subsequent calls to normalize().

=head2 Result Object

=head3 get_status()

Returns the status of all the filters:

=over 4

=item True means no violations

=item -1 (i.e. still true) means there were warnings but no violations.

=item False means there was at least one violation and possibly warnings.

=back

=head3 get_warning_count()

Return the number of warnings from all filters combined.

=head3 get_violation_count()

Return the number of violations from all filters combined.

=head3 get_filter_results()

Return an array ref of filter result objects (documented in L</"Filter Result Object">).

=head3 get_orig_str()

Get the phrase as passed in before any modifications by filters.

=head3 get_aggregate_result()

Get the phrase after all filters had a chance to modify it.

=head3 filters_modify_string()

Returns true if any of the filters resulted in a string different from what you passed it. False otherwise.

=head2 Filter Result Object

=head3 Intended for use in a filter module.

See L</"ANATOMY OF A FILTER MODULE"> for more info.

=head4 add_violation()

Add a violation.

=head4 add_warning()

Add a warning.

=head4 get_string_sr()

Returns a SCALAR reference to the modified version of the string that the filter can use to modify the string.

=head4 return_value()

returns an array of the status, violation count, warning count, and filter_modifies_string().

It is what the filter’s normalize_maketext_string() should return;

=head4 get_maketext_object()

Returns the object you instantiated the L</"Main object"> with.

If you did not specify an argument a L<Locale::Maketext::Utils::Mock> object is used. That means all the cool stuff in your locale object that you might want to use in your filter will not be available.

=head4 run_extra_filters()

Returns a boolean value of if we are running extra filters or not.

    if ( $filter->run_extra_filters() ) {
        # do extra check for violations/warnings here
    }

You can use this to check if the filter should run certain tests or not. You can even skip an entire filter by use of L<return_value_noop()>.

=head4 return_value_noop()

Get an appropriate L<return_value()> for when the entire filter falls under the category of L</extra filters>.

    return $filter->return_value_noop() if !$filter->run_extra_filters();

=head3 Intended for use when processing results.

These can be used in a filter module’s filter code if you find use for them there. See L</"ANATOMY OF A FILTER MODULE"> for more info.

=head4 get_status()

Returns the status of the filter:

=over 4

=item True means no violations

=item -1 (i.e. still true) means there were warnings but no violations.

=item False means there was at least one violation and possibly warnings.

=back

=head4 get_package()

Get the current filter’s package.

=head4 get_orig_str()

Get the phrase as passed in before any modifications by the filter.

=head4 get_new_str()

Get the phrase after the filter had a chance to modify it.

=head4 get_violations()

Return an array ref of violations added via add_violation().

If there are no violations it returns false.

=head4 get_warnings()

Return an array ref of violations added via add_warning().

If there are no warnings it returns false.

=head4 get_warning_count()

Returns the number of warnings the filter resulted in.

=head4 get_violation_count()

Returns the number of violations the filter resulted in.

=head4 filter_modifies_string()

Returns true if the filter resulted in a string different from what you passed it. False otherwise.

=head1 DEFAULT FILTERS

The included default filters are listed below in the order they are executed by default.

=over 4

=item L<NonBytesStr|Locale::Maketext::Utils::Phrase::Norm::NonBytesStr>

=item L<WhiteSpace|Locale::Maketext::Utils::Phrase::Norm::WhiteSpace>

=item L<Grapheme|Locale::Maketext::Utils::Phrase::Norm::Grapheme>

=item L<Ampersand|Locale::Maketext::Utils::Phrase::Norm::Ampersand>

=item L<Markup|Locale::Maketext::Utils::Phrase::Norm::Markup>

=item L<Ellipsis|Locale::Maketext::Utils::Phrase::Norm::Ellipsis>

=item L<BeginUpper|Locale::Maketext::Utils::Phrase::Norm::BeginUpper>

=item L<EndPunc|Locale::Maketext::Utils::Phrase::Norm::EndPunc>

=item L<Consider|Locale::Maketext::Utils::Phrase::Norm::Consider>

=item L<Escapes|Locale::Maketext::Utils::Phrase::Norm::Escapes>

=item L<Compiles|Locale::Maketext::Utils::Phrase::Norm::Compiles>

=back

=head2 extra filters

It may be desireable for some filters to not run by default but still be easily applied when needed.

The extra filter mechanism allows for this as documented specifically throught this POD.

No filters fall under L</extra filters> currently.

=head1 ANATOMY OF A FILTER MODULE

A filter module is simply a package that defines a function that does the filtering of the phrase.

=head2 normalize_maketext_string()

This gets passed a single argument: the L</"Filter Result Object"> that defines data about the phrase.

That object can be used to do the actual checks, modifications if any, and return the expected info back (via $filter->return_value).

    package My::Phrase::Filter::X;

    sub normalize_maketext_string {
        my ($filter) = @_;

        my $string_sr = $filter->get_string_sr();

        if (${$string_sr} =~ s/X/[comment,unexpected X]/g) {
              $filter->add_warning('X might be invalid might wanna check that');
        #         or
        #      $filter->add_violation('Text of violation here');
        }

        return $filter->return_value;
    }

    1;

It’s a good idea to explain the filter in it’s POD. Check out L<_Stub|Locale::Maketext::Utils::Phrase::Norm::_Stub> for some boilerplate.

=head1 DIAGNOSTICS

=over

=item C<< %s does not implement normalize_maketext_string() >>

The constructor method was able to load the filter %s but that class does not have a normalize_maketext_string() method.

=item C<< Can't locate %s.pm in @INC … >>

The constructor method was not able to load the filter %s, the actual error comes from perl via $@ from L<Module::Want>

=item C<< Filter list is empty! >>

After all initialization and no other errors the list of filters is somehow empty.

=item C<< Given maketext object does not have a makethis() method. >>

The value of the maketext_object key you passed to the constructor method or the value passed to set_maketext_object() does not define a makethis() method.

=item C<< Given maketext object is not a reference. >>

The value of the maketext_object key you passed to the constructor method or the value passed to set_maketext_object() is not an object.

=item C<< new() is deprecated, use new_source() instead >>

Your code uses the deprecated constructor and needs to be updated.

=item C<< You must pass a value to normalize() >>

Your code called normalize() without giving it a value to, well, normalize.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Locale::Maketext::Utils::Phrase::Norm requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Module::Want>, L<Encode> (for the L<WhiteSpace|Locale::Maketext::Utils::Phrase::Norm::WhiteSpace> filter)

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-locale-maketext-utils@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Locale::Maketext::Utils::Phrase::cPanel>

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012 cPanel, Inc. C<< <copyright@cpanel.net>> >>. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.1 or, at your option,
any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
