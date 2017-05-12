
=head1 NAME

Form::Maker::Introduction - An introduction to Forms

=head2 DESCRIPTION

The goal of the Form project is to make the creation and use of web
forms as trivial as possible, whilst still providing the ability to
customise any aspect in any way you choose.

Details of all the different components of a form and the phases of form
generation are detailed in the docs of the appropriate modules. The aim
of this document is merely to give an overview of the sorts of things
that are possible, rather than a detailed explanation of how to do each
thing.

The simplest form is one that already exists:

    my $form = Form::Maker->make("Form::Outline::Login");

This will give you a standard login form with username and password
fields (the password field, of course, being of type 'password' so that
the text isn't echoed to the screen as the user types it.

To print this out as HTML you can then simply call

    print $form;

Arriving at that point is, of course, more complicated, so let's look at
the various ways forms can be built up and customised:

=head2 Starting From Scratch

Many (if not most) of the forms you create won't already have been
pre-built for you (although hopefully CPAN will contain lots that have,
and you'll consider adding more there!)

So, most times you'll have to start with a clean slate:

    my $form = Form::Maker->make;

You then add whatever fields you want on your form. In the case of the
login example this would be:

    $form->add_fields(qw/username password/);

If we just pass a list of strings like this, the Form Maker will assume
that every field is a normal HTML textfield, unless it matches a few
known exceptions. Luckily for us, 'C<password>' is one of these exceptions,
and it will become an HTML password field. (This is implemented internally
as a C<Form::Decorator>, which you can switch off if you don't want this
behaviour)

If you need more control over this you can pass C<Form::Field> objects
instead:

    my $form = Form::Maker->make;
    $form->add_fields(
            Form::Field::Text->new({ name => "username" }),
            Form::Field::Password->new({ name => "password" }),
    );

(See L<Form::Field> for more information on what can be done here)

=head2 Adding Restrictions

The default login form just has a simple username and password. On many
sites the username is actually the user's email address. In such a case
we can alter the form to restrict the input to something that looks like
an email address.

We can do this very naively by providing a regular expression:

    my $form = Form::Maker->make("Form::Outline::Login");
    $form->add_validation(username => qr/\@/);

This will do two main things. Firstly, it will add some JavaScript to
provide client side validation of this input field. Secondly, server
side form processing code will be able to ask this form for a list of
restrictions it can check against (The Form project is itself only
concerned with creating the forms, but it will provide helpful
information to whatever form processing code you're using).

Of course, JavaScript's regex engine isn't exactly the same as Perl's,
so if you take this approach, you need to ensure that your regex will
work in both. If you need to provide a different regex for Perl and
JavaScript, then pass them as a hashref:

    $form->add_validation(username => {
        perl => qr/$RE{email}/,
        javascript => '/^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/'
    );

Of course this gets clumsy quickly, so we can encapsulate all that in a
Validator:

    my $form = Form::Maker->make("Form::Outline::Login");
    $form->add_validation(username => 'Form::Validator::Email');

=head2 Creating Your Own Outlines

You are, of course, free to just create and use 'anonymous' forms like
this everywhere you want. But you can easily turn your form into an
Outline that can be pulled in from everywhere (and, if it's generic or
useful enough, even released to CPAN). The syntax is almost identical,
except you're setting the information up on the class, rather than the
instance:

    package My::Form::Outline::Login;

    __PACKAGE__->add_fields(
            Form::Field::Text->new({ name => "username" }),
            Form::Field::Password->new({ name => "password" }),
    );
    __PACKAGE__->add_validation(username => 'Form::Validator::Email');

Of course, if you're just extending an Outline that already exists, you
can do this through subclassing:

    package My::Form::Outline::Login;
    use base 'Form::Outline::Login';

    __PACKAGE__->add_validation(username => 'Form::Validator::Email');

And now you can just make your form from that outline instead:

    my $form = Form::Maker->make("My::Form::Outline::Login");

=head2 Changing Global Behaviour

Of course, if your site requires an an email address for a username, you
may want to set things up so that, by default, every 'C<username>' field on
every form has suitable validation.

You can do this by providing a Decorator that adds a validator to any
'C<username>' field:

    package My::Form::Decorator::EmailUsername;

    sub decorate {
            my ($class, $form) = @_;
            foreach my $field (@{ $form->fields }) {
                    $field->add_validator('Form::Validator::Email')
                            if $field->name eq "username");
            }
            return $form;
    }

Then you subclass the basic C<Form::Maker> to apply this decorator to every
form:

    package My::Form::Maker;
    use base 'Form::Maker';

    __PACKAGE__->add_decorator('My::Form::Decorator::EmailUsername');

Now, when you want a form, you just need to ask your own Maker for it,
rather than the default one:

    my $form = My::Form::Maker->make("Form::Outline::Login");

=head2 Rendering

If you're happy with the default way in which Forms are rendered, then
rendering them is as simple as:

    print $form;

Usually, however, you're going to want more control over this. Again,
there are a couple of main ways to achieve this.

=head2 Rendering the Form piecemeal

The form is made up of several different components which can be printed
in turn:

    print $form->start;
    print $form->fieldset;
    print $form->buttons;
    print $form->end;

If you want even more control, printing 'C<fieldset>' is equivalent to:

    print $form->fieldset_start;
    print $_ foreach @{$form->fields};
    print $form->fieldset_end;

Similarly, printing 'C<buttons>' (submit, reset, etc) is equivalent to:

    print $_ foreach @{$form->buttons};

In a template, for example, you can iterate over these in whatever way
you choose, placing each element wherever you like. Each element is
actually an C<HTML::Element> object, so you can also make any changes you
need to how those get displayed. (Strictly they're an C<HTML::Element>
subclass that knows a little more about the Form, and how to output
themselves, but you shouldn't really need to know much about that).

=head2 Overriding the Renderer

If you want to change how Forms are rendered in a more general way, you
can also provide your own Renderer. By default all Forms are rendered by
C<Form::Renderer::HTML>. But you can override that, either for a specific
form:

    my $form = Form::Maker->make("Form::Outline::Login");
    $form->renderer("My::Form::Renderer");
    print $form;

or your own outline:

    package My::Form::Outline::Login;
    use base 'Form::Outline::Login';
    ...
    __PACKAGE__->renderer("My::Form::Renderer");

or globally through your Maker:

    package My::Form::Maker;
    use base 'Form::Maker';
    ...
    __PACKAGE__->renderer("My::Form::Renderer");

You'll need to study L<Form::Renderer> to work out what you can actually do
here.

=cut
