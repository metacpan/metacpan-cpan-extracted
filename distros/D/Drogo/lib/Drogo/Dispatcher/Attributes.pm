use attributes;
use warnings;
use strict;

package Drogo::Dispatcher::Attributes;

=head1 NAME 

Drogo::Dispatcher::Attributes

  Attributes:
     Index, Page, Action, ActionMatch, ActionRegex

=head1 Synopsis

Code attributes.

=head1 Methods

=cut

our ( %dispatch_flags, %cached_flags );

sub MODIFY_CODE_ATTRIBUTES
{
    my ($pack, $ref, @attr) = @_;

    for my $attr ( @attr ) {

        # ensure a $dispatch_flags{$pack} hashref, always
        $dispatch_flags{$pack} = { }
            unless exists $dispatch_flags{$pack};

        if  ($attr eq 'Index')
        {
            $dispatch_flags{$pack}{$ref} = 'index';
        }
        elsif  ($attr eq 'Action')
        {
            $dispatch_flags{$pack}{$ref} = 'action';
        }
        elsif  ($attr eq 'ActionMatch')
        {
            $dispatch_flags{$pack}{$ref} = 'action_match';
        }
        elsif  ($attr =~ /^ActionRegex/)
        {
            if ($attr =~ /^ActionRegex\(['"](.*)['"]\)$/)
            {
                my $regex = $1;

                eval { qr/$regex/ };
                die "Invalid ActionRegex in $pack (ref) $attr: $@\n"
                    if $@;

                $dispatch_flags{$pack}{$ref} = "action_regex-${regex}";
            }
            else
            {
                die "Invalid ActionRegex in $pack (ref): $attr\n";
            }
        }
        elsif  ($attr =~ /^Path/)
        {
            my $desc;
            $desc = $1 if $attr =~ /\(['"](.*?)['"]\)$/;

            $dispatch_flags{$pack}{$ref} = "path-${desc}";
       }
    }

    return ();
}

sub FETCH_CODE_ATTRIBUTES { $dispatch_flags{shift}{shift} }

=head2 get_dispatch_flags

Returns all autoflags specific to a package with inheritance.

=cut

sub get_dispatch_flags
{
    my $self  = shift;
    my $class = ref $self ? ref $self : $self;

    $cached_flags{$class} = $class->get_package_dispatch_flags
        unless exists $cached_flags{$class};

    return $cached_flags{$class};
}

=head2 get_package_dispatch_flags

Get autoflags, only specific to the called package.

=cut

sub get_package_dispatch_flags
{
    my $self      = shift;
    my $class     = ref $self ? ref $self : $self;
    my @code_refs = keys %{$dispatch_flags{$class}};

    my %flag_methods;
    {
        no strict 'refs';
        for my $key (keys %{"${class}::"})
        {
            my $code_ref = "${class}::${key}";

            if (defined &$code_ref)
            {
                my $code = \&$code_ref;

                $flag_methods{"$key"} = $dispatch_flags{"$class"}{"$code"}
                    if grep { "$code" eq "$_" } @code_refs;
            }
        }
    }

    return \%flag_methods;
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
