package HTML::FormHandler::Widget::Theme::Bootstrap;
# ABSTRACT: sample bootstrap theme
$HTML::FormHandler::Widget::Theme::Bootstrap::VERSION = '0.40068';

use Moose::Role;
with 'HTML::FormHandler::Widget::Theme::BootstrapFormMessages';

after 'before_build' => sub {
    my $self = shift;
    $self->set_widget_wrapper('Bootstrap')
       if $self->widget_wrapper eq 'Simple';
};

sub build_form_element_class { ['form-horizontal'] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Theme::Bootstrap - sample bootstrap theme

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Also see L<HTML::FormHandler::Manual::Rendering>.

Sample Bootstrap theme role. Can be applied to your subclass of HTML::FormHandler.
Sets the widget wrapper to 'Bootstrap' and renders form messages using Bootstrap
formatting and classes.

There is an example app using Bootstrap at http://github.com/gshank/formhandler-example.

This is a lightweight example of what you could do in your own custom
Bootstrap theme. The heavy lifting is done by the Bootstrap wrapper,
L<HTML::FormHandler::Widget::Wrapper::Bootstrap>,
which you can use by itself in your form with:

    has '+widget_wrapper' => ( default => 'Bootstrap' );

It also uses L<HTML::FormHandler::Widget::Theme::BootstrapFormMessages>
to render the form messages in a Bootstrap style:

   <div class="alert alert-error">
       <span class="error_message">....</span>
   </div>

By default this does 'form-horizontal' with 'build_form_element_class'.
Implement your own sub to use 'form-vertical':

   sub build_form_element_class { ['form-vertical'] }

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
