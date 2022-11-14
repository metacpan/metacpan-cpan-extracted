package HTML::Blitz::Template;
use HTML::Blitz::pragma;
use Carp qw(croak);

our $VERSION = '0.01';

method new($class: :$_codegen) {
    bless {
        _codegen => $_codegen,
    }, $class
}

method _codegen() {
    $self->{_codegen}
}

method _perl_src() {
    $self->{_perl_src} //= $self->{_codegen}->assemble(
        data_format         => 'sigil',
        data_format_mapping => {
            array => '',
            bool  => '',
            func  => '',
            html  => '',
            str   => '',
        },
    )
}

method compile_to_string() {
    $self->_perl_src
}

method compile_to_fh($fh, $name = $fh) {
    print $fh $self->_perl_src
        or croak "Can't write to $name: $!";
}

method compile_to_file($file, :$do_sync = undef) {
    open my $fh, '>:encoding(UTF-8)', $file
        or croak "Can't open $file: $!";
    $self->compile_to_fh($fh, $file);
    if ($do_sync) {
        $fh->flush
            or croak "Can't flush $file: $!";
        $fh->sync
            or croak "Can't sync $file: $!";
    }
    close $fh
        or croak "Can't close $file: $!";
}

method compile_to_sub() {
    $self->{_sub} //= do {
        my $err;
        my $src = $self->_perl_src;
        my $fn;
        {
            local $@;
            $fn = eval $src;
            $err = $@;
        }
        $fn // croak $err
    }
}

method process($data = {}) {
    $self->compile_to_sub->($data)
}

1
__END__

=head1 NAME

HTML::Blitz::Template - pre-parsed HTML documents ready for template expansion

=head1 SYNOPSIS

    my $template = $blitz->apply_to_file("src/template.html");

    my $data = {
        title => $title,
        people => [
            { name => $name1, job => $job1 },
            { name => $name2, job => $job2 },
            { name => $name3, job => $job3 },
        ],
    };
    my $html = $template->process($data);

    my $func = $template->compile_to_sub;
    my $html = $func->($data);

    $template->compile_to_file("precompiled/template.pl");
    my $func = do "precompiled/template.pl";
    my $html = $func->($data);

=head1 DESCRIPTION

Objects of this class represent document templates that result from applying a
set of template actions to an HTML source document. See L<HTML::Blitz>.

There are three things you can do with an HTML::Blitz::Template object:

=over

=item 1.

Give it a set of variables and get an HTML document back. This involves the
L</compile_to_sub> method and calling the returned function (or using the
L</process> method, which does it for you).

=item 2.

Serialize the code to a string (via L</compile_to_string>) or straight to disk
(via L</compile_to_fh> or L</compile_to_file>).

=item 3.

Use it as a component of another template. See the
L<C<replace_inner_template>|HTML::Blitz/"C<['replace_inner_template', TEMPLATE]>"> and
L<C<replace_outer_template>|HTML::Blitz/"C<['replace_outer_template', TEMPLATE]>"> actions
in L<HTML::Blitz>.

=back

=head1 METHODS

This class has no public constructor. Instances can be created with
L<HTML::Blitz/apply_to_html> and L<HTML::Blitz/apply_to_file>.

=head2 compile_to_string

    my $code = $template->compile_to_string;

Creates Perl code that implements the functionality of the template (which is
the result of applying a rule set to an HTML source document) and returns it as
a string.

=head2 compile_to_sub

    my $func = $template->compile_to_sub;
    my $html = $func->($variables);

Like L</compile_to_string>, but returns a code reference instead of source
code. Equivalent to C<< eval $template->compile_to_string >>, but without
clobbering C<$@>. It also caches the generated function internally, so calling
C<compile_to_sub> twice will return the same reference.

The returned code reference takes an argument that specifies the variables that
the template is to be instantiated with. This argument takes the form of a
variable environment.

A I<variable environment> is a hash reference whose keys are the names of
runtime variables used by the template (and the values are the corresponding
values). Template variables fall into the following categories:

=over

=item *

Strings.

These are used to expand variables in text (e.g. C<replace_inner_var>) and
attribute values (e.g. C<set_attribute_var>).

=item *

Booleans.

These are used in conditions (e.g. C<remove_if>).

=item *

Functions.

These are used to dynamically transform text (e.g. C<transform_inner_var>) and
attribute values (e.g. C<transform_attribute_var>).

=item *

Templates (i.e. instances of L<HTML::Blitz::Template>).

These are used to embed sub-templates into other templates, as a form of
component reuse (e.g. C<replace_inner_template>).

=item *

Dynamic HTML (i.e. instances of L<HTML::Blitz::Builder>).

These are used to insert dynamically generated HTML fragments (e.g.
C<replace_inner_dyn_builder>).

=item *

Arrays (of variable environments).

These are used to provide input values to repeated subsections of the source
document (e.g. C<repeat_outer>).

=back

=head2 process

    my $html = $template->process($variables);

Equivalent to C<< $template->compile_to_sub->($variables) >>.

=head2 compile_to_fh

    $template->compile_to_fh($filehandle [, $filename ]);

Like L</compile_to_string>, but writes the resulting code to the file handle
passed as the first argument instead of returning it as a string. The second
argument is optional; it is used in the error message thrown if the write
fails.

=head2 compile_to_file

    $template->compile_to_file($filename);
    $template->compile_to_file($filename, do_sync => 1);

Like L</compile_to_string>, but writes the resulting code to the file whose
name is passed as the first argument. (If the file doesn't exist, it is
created; otherwise it is overwritten.)

If C<< do_sync => 1 >> is passed, L<< IO::Handle/"$io->sync" >> is called
before the file is closed, which flushes file data at the OS level (see
L<fsync(2)>).

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2022 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU Affero General Public License|https://www.gnu.org/licenses/agpl-3.0.txt>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

=head1 SEE ALSO

L<HTML::Blitz>
