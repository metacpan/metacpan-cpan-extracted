package Mail::Builder::Simple;

use strict;
use warnings;
use Mail::Builder;
use Email::Sender::Simple;
use Email::Valid;
use Encode;
use Carp qw/cluck/;
use Config::Any;
use Module::Load;
use base 'Mail::Builder';

use 5.008_008;

our $VERSION = '0.16';

sub new {
    my @params = @_;
    my $class  = shift @params;
    my $args   = ref( $params[0] ) eq 'HASH' ? $params[0] : {@params}
      or cluck 'Can\'t create mail object. Invalid parameters hash';

    my $self = $class->SUPER::new();
    bless $self, $class;

    my @fields = qw/from reply organization returnpath sender priority
      subject plaintext htmltext language to cc bcc attachment image mailer/;

    $self->{mail_fields} = join q{|}, @fields;

    $self->_add_args($args);

    return bless $self, $class;
}

sub _add_args {
    my @params = @_;
    my $self   = shift @params;
    my $args   = ref( $params[0] ) eq 'HASH' ? $params[0] : {@params}
      or return;

    if ( $args->{mail_client} ) {
        $self->{mail_client} = $args->{mail_client};
    }

    if ( $args->{template_args} ) {
        $self->{template_args} = $args->{template_args};
    }

    if ( $args->{template_vars} ) {
        $self->{template_vars} = $args->{template_vars};
    }

    if ( my $config_file = $args->{config_file} ) {
        my $conf = Config::Any->load_files(
            {
                files       => [$config_file],
                use_ext     => 1,
                driver_args => { General => { -UTF8 => 1 } },
            }
        );

        delete $args->{config_file};

        $self->_add_args( $conf->[0]->{$config_file} );
    }

    foreach my $field ( sort keys %{$args} ) {
        $self->_add_arg( $args, $field );
    }

    return 1;
}

sub _add_arg {
    my ( $self, $args, $field ) = @_;

    return if $field !~ /^(?:$self->{mail_fields})$/smox;

    my $value = $args->{$field};

    #If the value is an arrayref
    if ( $value and ref($value) eq 'ARRAY' ) {

        #There are more items
        if ( $value->[0] and $value->[0] eq 'MORE' ) {
            shift @{$value};
            $self->_process_array( $args, $field, $value );
        }

        #There are more items
        elsif ( $value->[0] and ref( $value->[0] ) eq 'ARRAY' ) {
            $self->_process_array( $args, $field, $value );
        }

        #There is an item with one or more fields
        elsif ( $value->[0] and not ref( $value->[0] ) ) {
            $self->_process_item( $args, $field, $value );
        }
        else {
            cluck 'Items inside arrayref should be scalar/arrayref.';
        }
    }

    #The value is a scalar
    elsif ( $value and not ref $value ) {
        $self->_set_or_add( $field, $value );
    }
    else {
        cluck "Value for $field should be scalar/an arrayref";
    }

    return 1;
}

sub _process_array {
    my ( $self, $args, $field, $value ) = @_;

    foreach my $item ( @{$value} ) {
        $self->_process_item( $args, $field, $item );
    }

    return 1;
}

sub _process_item {
    my ( $self, $args, $field, $item ) = @_;

    #This item is an arrayref
    if ( ref($item) eq 'ARRAY' ) {

        #This item is a template
        if ( $item->[-1] =~ /^:(.+)/smox ) {
            my $result = $self->_process_template( $args, $item, $field );
            $self->_set_or_add( $field, $result );
        }

        #It is not a template
        else {
            $self->_set_or_add( $field, @{$item} );
        }
    }

    #It is a scalar
    elsif ( !ref $item ) {
        $self->_set_or_add( $field, $item );
    }
    else {
        cluck 'The elements of the array can be just scalars.';
    }

    return 1;
}

sub _process_template {
    my ( $self, $args, $item, $field ) = @_;

    my $type = substr $item->[-1], 1;
    ( $type, my $source ) = split /-/smx, $type;
    $source ||= 'file';
    delete $item->[-1];

    #Get and overwrite template_args
    my $template_args = $self->{template_args};
    if ( $args->{template_args} ) {
        foreach ( keys %{ $args->{template_args} } ) {
            $template_args->{$_} = $args->{template_args}->{$_};
        }
    }

    #If this template has its own settings:
    if ( ref( $item->[-1] ) eq 'HASH' ) {
        my $template_settings = pop @{$item};
        foreach ( keys %{$template_settings} ) {

            #Insert and overwrite the new template settings:
            $template_args->{$_} = $template_settings->{$_};
        }
    }

    #Get and overwrite template_vars
    my $template_vars = $self->{template_vars};
    if ( $args->{template_vars} ) {
        foreach ( keys %{ $args->{template_vars} } ) {
            $template_vars->{$_} = $args->{template_vars}->{$_};
        }
    }

    #If this template has its own variables:
    if ( ref( $item->[-1] ) eq 'HASH' ) {
        my $template_variables = pop @{$item};
        foreach ( keys %{$template_variables} ) {

            #Insert and overwrite the template vars:
            $template_vars->{$_} = $template_variables->{$_};
        }
    }

    load "Mail::Builder::Simple::$type";

    my $t =
      "Mail::Builder::Simple::$type"->new( $template_args, $template_vars );

    $item->[0] = $t->process( $item->[0], $source );

    if ( $field eq 'attachment' ) {
        return Mail::Builder::Attachment->new( \$item->[0], $item->[1], $item->[2] );
    }
    else {
        return $item;
    }
}

sub _set_or_add {
    my ( $self, $field, @value ) = @_;

    return if not $self->_check_email_valid( $field, @value );

    if (   $field eq 'from'
        or $field eq 'reply'
        or $field eq 'organization'
        or $field eq 'returnpath'
        or $field eq 'sender'
        or $field eq 'priority'
        or $field eq 'subject'
        or $field eq 'language'
        or $field eq 'mailer' )
    {
        $self->$field(@value);
    }
    elsif ( $field eq 'plaintext' or $field eq 'htmltext' ) {
        if ( ref( $value[0] ) eq 'ARRAY' ) {
            $self->$field( $value[0][0] );
        }
        else {
            $self->$field( $value[0] );
        }
    }
    else {
        if ( $self->$field ) {
            $self->$field->add(@value);
        }
        else {
            $self->$field(@value);
        }
    }

    return 1;
}

sub _check_email_valid {
    my ( $self, $field, @value ) = @_;

    if (   $field eq 'from'
        or $field eq 'to'
        or $field eq 'cc'
        or $field eq 'bcc'
        or $field eq 'reply'
        or $field eq 'returnpath' )
    {
        if ( !Email::Valid->address( $value[0] ) ) {
            warn "Bad email address: $value[0]";
            return;
        }
    }

    return 1;
}

sub sendmail {
    my @params = @_;
    my $self   = shift @params;
    my $args   = ref( $params[0] ) eq 'HASH' ? $params[0] : {@params}
      or cluck 'Can\'t send mail. Invalid parameters hash';

    #Add message fields:
    $self->_add_args($args);

    #Create the email message
    my $entity = $self->build_message;

    #Add custom headers if there are:
    $self->_add_custom_headers( $entity, $args );

    my $mail_client = $self->{mail_client};

    my $mailer = $self->_load_mailer($mail_client);

    my $mailer_args = $self->_mailer_args($mail_client);

    #Accept the old keys for compatibility with older versions:
    $mailer_args = $self->_asure_compatibility($mailer_args);

    #If the mailer_args contains other addresses to send the email to
    #than the ones from the email:
    my $different_addresses = $self->_different_email_addresses($mailer_args);

    #For sending with send() or try_to_send()
    my $transport = $mailer->new( %{$mailer_args} );

    if ( $mail_client->{live_on_error} ) {
        Email::Sender::Simple->try_to_send( $entity->stringify,
            { transport => $transport, %{$different_addresses} } );
    }
    else {
        Email::Sender::Simple->send( $entity->stringify,
            { transport => $transport, %{$different_addresses} } );
    }

    #Reset To, Cc and BcC:
    $self->to->reset;
    $self->cc->reset;
    $self->bcc->reset;

    return 1;
}

*send = \&sendmail;

sub _add_custom_headers {
    my ( $self, $entity, $args ) = @_;

    foreach my $field ( keys %{$args} ) {
        next if $field =~ /^(?:$self->{mail_fields})$/smox;

        $entity->head->replace( $field,
            Encode::encode( 'MIME-Header', $args->{$field} ) );
    }

    return 1;
}

sub _load_mailer {
    my ( $self, $mail_client ) = @_;

    my $mailer;

    if ($mail_client) {
        $mailer = $mail_client->{mailer};
    }

    if ( !$mailer ) {
        $mailer = 'Sendmail';
    }

    if ( $mailer !~ /^Email::Sender::Transport/smox ) {
        $mailer = 'Email::Sender::Transport::' . $mailer;
    }

    load $mailer;

    return $mailer;
}

sub _mailer_args {
    my ( $self, $mail_client ) = @_;

    my %mailer_args = ();
    if ( ref( $mail_client->{mailer_args} ) eq 'HASH' ) {
        %mailer_args = %{ $mail_client->{mailer_args} };
    }
    elsif ( ref( $mail_client->{mailer_args} ) eq 'ARRAY' ) {
        %mailer_args = @{ $mail_client->{mailer_args} };
    }

    return \%mailer_args;
}

sub _asure_compatibility {
    my ( $self, $mailer_args ) = @_;

    if ( $mailer_args->{Host} ) {
        $mailer_args->{host} = delete $mailer_args->{Host};
    }

    if ( $mailer_args->{username} ) {
        $mailer_args->{sasl_username} = $mailer_args->{username};
    }

    if ( $mailer_args->{password} ) {
        $mailer_args->{sasl_password} = $mailer_args->{password};
    }

    #Add the port if it was provided as host:port
    if ( $mailer_args->{host} and $mailer_args->{host} =~ /:(\d+)$/smx ) {
        my $port = $1;
        $mailer_args->{host} =~ s/:\d+$//smx;
        $mailer_args->{port} = $port;
    }

    return $mailer_args;
}

sub _different_email_addresses {
    my ( $self, $mailer_args ) = @_;

    my %different_addresses;

    if ( $mailer_args->{to} ) {
        $different_addresses{to} = delete $mailer_args->{to};
    }

    if ( $mailer_args->{cc} ) {
        $different_addresses{cc} = delete $mailer_args->{cc};
    }

    if ( $mailer_args->{from} ) {
        $different_addresses{from} = delete $mailer_args->{from};
    }

    return \%different_addresses;
}

1;

__END__

=head1 NAME

Mail::Builder::Simple - Send UTF-8 HTML and text email with attachments and inline images, eventually using templates

=head1 VERSION

Version 0.15

=head1 SYNOPSIS

 # Send a plain text email with Sendmail:

 use Mail::Builder::Simple;

 my $mail = Mail::Builder::Simple->new;

 $mail->send(
  from => 'me@host.com',
  to => 'you@yourhost.com',
  subject => 'The subject with UTF-8 chars',
  plaintext => "Hello,\n\nHow are you?\n",
 );

 # Send the email with an SMTP server:

 $mail->send(
  mail_client => {
   mailer => 'SMTP',
   mailer_args => {host => 'smtp.host.com'},
  },
  from => 'me@host.com',
  to => 'you@yourhost.com',
  subject => 'The subject with UTF-8 chars',
  plaintext => "Hello,\n\nHow are you?\n",
 );

 # Send a text and HTML email with an attachment and an inline image
 # Specify the displayed name for To: and From: fields and add other headers

 $mail->send(
  from => ['me@host.com', 'My Name'],
  to => ['you@yourhost.com', 'Your Name'],
  reply => 'foo@anotherhost.com',
  subject => 'The subject with UTF-8 chars',
  plaintext => "Hello,\n\nHow are you?\n\n",
  htmltext => "<h1>Hello,</h1> <p>How are you?</p>",
  attachment => 'file.pdf',
  image => 'logo.png',
  priority => 1,
  mailer => 'My Mailer 0.01',
 );

Warning! The previous version of this module was using C<Email::Send> for sending mail but because of the issues of Email::Send, this version uses C<Email::Sender::Simple> and because of this change there may appear incompatibilities (although at least for the programs which are using Sendmail and SMTP mailers there shouldn't be any issues). Look for "Compatibility" below.

=head1 DESCRIPTION

C<Mail::Builder::Simple> can create email messages with L<Mail::Builder|Mail::Builder> and send them with L<Email::Sender::Simple|Email::Sender::Simple>. It has the following features:

=over

=item UTF-8 encoding

C<Mail::Builder::Simple> automaticly encodes the body and headers of the email messages to UTF-8, so they can display the special chars in other languages than English correctly.

=item attachments

C<Mail::Builder::Simple> allow adding one or more attachments to the message, without needing to specify their Content-Type if you don't want to.

The attachments can be files saved on the disk or can be created on the fly, eventually using templates.

=item images

C<Mail::Builder::Simple> can add inline images that will be displayed in the HTML part of the message.

=item templates

The body and the attachments can be created using a template, either using external template files or templates from scalar variables.

C<Mail::Builder::Simple> uses other modules like L<Mail::Builder::Simple::TT|Mail::Builder::Simple::TT> and L<Mail::Builder::Simple::HTML::Template|Mail::Builder::Simple::HTML::Template> in order to allow using L<Template-Toolkit|Template> or L<HTML::Template|HTML::Template> templates.

For using another templating system, you can create a module like these 2 modules.

=item mail sender

C<Mail::Builder::Simple> can send the email messages using any of the mailers allowed by L<Email::Sender::Simple|Email::Sender::Simple> and some of them are: Sendmail, SMTP, SMTP::Persistent, Maildir, Mbox.

=item configuration file

All the parameters that can be sent to the C<new()> function can be also stored in a configuration file, and this file can be used in more applications.

For example, you could save the mailer type, the mailer host, username and password and maybe the C<From:> field in a configuration file, so you won't need to specify them each time when you want to send an email.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The configuration file is specified using the C<config_file> key when the C<new()> constructor is called.

It is explained below.

=head1 SUBROUTINES/METHODS

Mail::Builder::Simple offers the following methods:

=over

=item new()

This is the constructor of the C<Mail::Builder::Simple> object. This object is a L<Mail::Builder|Mail::Builder> object also, so you can use the methods from Mail::Builder on it if you want.

=item send()

This function sends the email. After sending the email, it cleans the C<To:>, C<CC:> and C<BCC:> fields, so you can send the already built message to somebody else if you want, needing to specify only the recipient's email address.

=back

These 2 functions can receive a hash with parameters that have the keys explained below.

=head1 Parameters

=head2 mail_client

This parameter is optional.

It is a hashref with all the options needed to configure L<Email::Sender::Simple|Email::Sender::Simple> for sending the email messages.

It looks like:

 mail_client => {
  mailer => 'SMTP',
  mailer_args => {host => 'smtp.host.com'},
 },

where the mailer is the C<Email::Sender::Transport::> type of transporter you want to use, like 'SMTP', 'SMTP::Persistent', 'Sendmail', 'Maildir', 'Mbox', or other types supported by Email::Sender::Simple.

C<mailer_args> receives all the configuration options that might be required by the specified mailer.

For example, for sending email with an SMTP host that require authentication, and listens to a non-standard port, you should use:

 mail_client => {
  mailer => 'SMTP',
  mailer_args => {
   host => 'smtp.host.com',
   port => 28,
   username => 'the_user',
   password => 'the_password',
  },
 },

If you want to send email using an SMTP server that uses SSL, for example send an email with Gmail, use:

 mail_client => {
  mailer => 'SMTP',
  mailer_args => {
   host => 'smtp.gmail.com',
   #port => 465, #The port 465 is the default when using SSL, so it is not necessary.
   username => 'the_user',
   password => 'the_password',
   ssl => 1,
  ],
 },

If the parameter C<mail_client> is not specified, the default mailer that is used is sendmail.

Starting with the version 0.10, the key C<mail_client> supports a new sub-key named C<live_on_error>. By default, if the email message can't be sent for different reasons, the module dies. If you set the key C<live_on_error> to true, the module doesn't die, but continues to run. This might be helpful if you try to send more email messages and if you are not interested if certain messages can't be sent.

You can use:

  mail_client => {
    mailer => 'SMTP',
    mailer_args => {host => 'smtp.host.com'},
    live_on_error => 1,
  },

The mailer_args key could have any other sub-keys, depending on the type of transport used. For example, the SMTP type of transport could have host, username, password, ssl and others. For more information look in the L<Email::Sender::Transport::SMTP|Email::Sender::Transport::SMTP> or other module which is used.

The mailer_args key could also contain the C<to>, C<cc> and C<from> keys, which are used if you want to send the email message to addresses specified by them, and not to the addresses specified when creating the email message.

In the following example, the email message is sent to good-email@host.com and not to fake-email@host.com:

  my $mail = Mail::Builder::Simple->new(
    mail_client => {
      mailer => 'SMTP',
      mailer_args => {
        host => 'smtp.host.com',
        to => 'good-email@host.com',
      },
    },
  );

  $mail->send(
    to => 'fake-email@host.com',
    from => 'me@host.com',
    subject => 'The subject',
    htmltext => '<h1>Hello</h1><p>The body of the message...</p>',
  );

=head2 template_args

This parameter is optional.

It is a hashref with all the arguments neede by the templating system you are using for creating the email body or the attachments.

C<template_args> can receive any kind of parameters, depending on the parameters which are accepted by the templating system used. C<Mail::Builder::Simple> allows using more templating systems even for creating a single email message. If more templating systems are used to create an email message, all the templates will use the arguments from the hashref C<template_args> unless overwritten, as you will see.

It could look like:

 template_args => {
  INCLUDE_PATH => '/path/to/templates', #default "."
  ENCODING => 'UTF-8', #The default is UTF-8 anyway
 },

=head2 template_vars

This parameter is optional.

It is a hashref with the pairs of variables from the templates and their values.

An example:

 template_vars => {
  name => 'Gil Bates',
  preferences => ['pizza', 'yogurt', 'blondes'],
 },

The variables from C<template_vars> will be used by all the templates which are used for creating the email message, unless some of them are overwritten as you will see.

The variables from template_args and template_vars should be defined before using them in a template. So for example if you want to send a message to more addressees and want to send template_vars to the send() method, you also need to send the template's parameters to send() method, because if you define the template earlier, in the new() method, the template won't see the template_vars.

Examples:

Don't do something like this:

  my $mail = Mail::Builder::Simple->new(
    from => 'my@host.com',
    subject => 'The subject',
    htmltext => ['template.tt', ':TT'],
  );
          
  $mail->send(
    to => 'one@host.com',
    template_vars => {name => 'Foo', age => 33},
  );

  $mail->send(
    to => 'two@host2.com',
    template_vars => {name => 'Bar', age => 28},
  );

But do it like this:

  my $mail = Mail::Builder::Simple->new(
    from => 'my@host.com',
    subject => 'The subject',
  );
          
  $mail->send(
    to => 'one@host.com',
    htmltext => ['template.tt', ':TT'],
    template_vars => {name => 'Foo', age => 33},
  );

  $mail->send(
    to => 'two@host2.com',
    htmltext => ['template.tt', ':TT'],
    template_vars => {name => 'Bar', age => 28},
  );

=head2 email message fields

These are the fields that create the email message. They are: C<from, to, cc, bcc, subject, plaintext, htmltext, attachment, image, priority, reply, organization, returnpath, sender, language, mailer>.

There are many ways of using these fields, and I will explain them below.

=head2 config_file

This parameter is optional.

It shows the path to a configuration file that holds some parameters you don't want to specify in each program.

The configuration file can be any type of file supported by L<Config::Any|Config::Any>: Apache config style (Config::General), JSON, INI files, XML, YAML or perl code.

Here is an example of a configuration file that uses L<Config::General|Config::General>:
(/home/user/email.conf)

 <mail_client>
  mailer SMTP
  <mailer_args>
   host smtp.host.com
   username user
   password passwd
  </mailer_args>
 </mail_client>
 from user@host.com

This configuration file contains options not only for the mailer, but it also contains the message field C<From:> which wouldn't need to be specified when sending an email.

Here is a program that sends an email using this configuration file:

 use Mail::Builder::Simple;

 my $mail = Mail::Builder::Simple->new(config_file => '/home/user/email.conf');

 $mail->send(
  to => 'you@yourhost.com',
  subject => 'The subject',
  htmltext => '<h1>Hello</h1> How are you?',
 );

As all other parameters shown until now, C<config_file> can be sent to both C<new()> and C<send()> functions.

=head2 other email message headers

You might need to include in your message some headers which are not in the list shown above. You can also add them as separate parameters, but they need to be capitalised exactly how they should appear in the email message.

These headers overwrite the previous set headers that have the same name and they can be sent as parameters only to the L</send> method, not to the L</new>.

Here is an example of including the header C<X-My-Special-Header>:

 $mail->send(
  to => 'you@yourhost.com',
  subject => 'The subject',
  plaintext => 'The body',
  'X-My-Special-Header' => 'This is my header',
 );

=head1 Using the email message fields

=head2 to, cc, bcc

Here are a few ways of using the C<To:> field:

As parameters to the C<new()> or C<send()> functions:

Set a single email address for the C<To:> field:

 to => 'you@host.com',

Set a single address and set the name that should be displayed in the C<To:> field:

 to => ['you@host.com', 'Your Name - with UTF-8 chars'],

Set more email addresses for the C<To:> field in 2 ways:

 to => ['MORE', 'you@host.com', 'he@host2.com', 'she@host3.com'],
 or
 to => [['you@host.com'], ['he@host2.com'], ['she@host3.com']],

Set more email addresses for the C<To:> field, and also set the names that should be displayed:

 to => [['you@host.com', 'Your Name'], ['he@host2.com', 'His Name']],

or as a method to the C<Mail::Builder::Simple> object:

Set an email address for the C<To:> field:

 $mail->to('you@host.com');

Set an email address for the C<To:> field, and also set the name which is displayed:

 $mail->to('you@host.com', 'Your Name');

Add the email address and the name which is displayed in the C<To:> field. You can repeat this for more times.

 $mail->to->add('you@host.com');
 $mail->to->add('he@host2.com', 'His Name');

You can set the C<CC:> or C<BCC:> fields of the message in the same way.

=head2 from

The C<From:> field can be set using:

 from => 'me@myhost.com',
 or
 from => ['me@myhost.com', 'My Name'],
 or
 $mail->from('me@myhost.com');
 or
 $mail->from('me@myhost.com', 'My Name');

=head2 subject

You can specify the subject field as:

 subject => 'The subject',
 or
 $mail->subject('The subject');

=head2 plaintext, htmltext

C<Mail::Builder::Simple> can create a plain-text message if you provide just the plaintext part, or a multipart message if you offer the htmltext also. You can even provide just the htmltext, and it will create the plaintext part automaticly.

You can create the body of the message using:

 plaintext => "Hello,\n\nHow are you?",
 htmltext => "<h1>Hello,</h1> <p>How are you?</p>",

=head2 attachments

The attachments can be added as parameters to C<new()> and C<send()> methods.

Attach a file without specifying an alternative name and its Content-Type:

 attachment => 'file.pdf',

Attach a file specifying an alternative name and its Content-Type:

 attachment => ['/path/to/file', 'filename.pdf', 'application/pdf'],

Attach more file without specifying alternative names and Content-Type in 2 ways:

 attachment => ['MORE', 'file1.pdf', 'file2.doc'],
 or
 attachment => [['file1.pdf'], ['file2.doc'], ['file3.html']],

Attach more files specifying their alternative names and Content-Type:

 attachment => [
  ['file1', 'file1.pdf', 'application/pdf'],
  ['file2', 'file2.pdf', 'application/pdf'],
 ],

or attach files using methods of the C<Mail::Builder::Simple> object. You can repeat this for more times:

 $mail->attachment->add('file1.pdf');
 or
 $mail->attachment->add('file', 'file.pdf', 'application/pdf');

=head2 images

C<Mail::Builder::Simple> allows attaching inline images that won't appear as attachments, but they will be displayed in the HTML part of the mail message.

You can add them as parameters to the C<new()> or C<send()> functions.

Add an inline image without specifying an alternative ID:

 image => 'image.png',

Add an inline image and specify an alternative ID:

 image => ['/path/to/image.png', 'image_id'],

Add more inline images without specifying an alternative ID:

 image => ['MORE', 'image1.png', 'image2.gif', 'image3.jpg'],
 or
image => [['image1.png'], ['image2.gif'], ['image3.gif']],

Add more inline images specifying an alternative ID:

 image => [
  ['/path/to/image1.png', 'logo'],
  ['image2.gif', 'img'],
  ['image3.jpg', 'picture'],
 ],

or you can add them using methods of the C<Mail::Builder::Simple> object. You can repeat it for more times:

 $mail->image->add('image.png');
 or
 $mail->image->add('/path/to/image.png', 'logo');

Only the .png, .jpg and .gif images can be attached as inline images.

The ID of the image is used for displaying the image in the HTML part of the email message, using something like the following HTML element for the "logo" ID:

 <img src="cid:logo" alt="logo">

If you don't provide an ID, one is automaticly generated and it will be the lowercase of the file name of the images, without the extension.

=head1 Using templates

C<Mail::Builder::Simple> allows to create the text and HTML body of the email message or the attachments using templates.

When the value of the parameters C<plaintext>, C<htmltext> and C<attachment> is an arrayref and the last element of that arrayref begins with ":", it means that this field is created using a template. The type of template is specified in that last element of the array.

=head2 Types of templates

C<Mail::Builder::Simple> uses other plugin modules like L<Mail::Builder::Simple::TT|Mail::Builder::Simple::TT> and L<Mail::Builder::Simple::HTML::Template|Mail::Builder::Simple::HTML::Template> for creating the content using L<Template-Toolkit|Template> or L<HTML::Template|HTML::Template>.

If you want to create the content using a templating system for which there isn't a plugin created yet, you can create that plugin. It is pretty simple.

The templates that can be used for the moment are:

 Scalar
 TT
 TT-scalar
 HTML::Template
 HTML::Template-scalar

Here are a few examples for creating a message plain text body using templates:

 # Create the plain text part of the email message using the TT template file "template.tt"
 
 my $mail = Mail::Builder::Simple->new;
 $mail->send(
  from => 'me@myhost.com',
  to => 'you@host.com',
  subject => 'The subject',
  plaintext => ['template.tt', ':TT'],
  template_args => {
   INCLUDE_PATH => '/path/to/templates',
  },
  template_vars => {
   name => 'My Name',
   age => 20,
  },
 );

and the template file in /path/to/templates/template.tt could contain:

 Hello [% name %],
 My age is [% age %].

 # Create the plain text part of the email message using a TT template from a scalar variable
 
 my $template = <<EOF;
 Hello [% name %],
 My age is [% age %].
 EOF

 my $mail = Mail::Builder::Simple->new;
 $mail->send(
  from => 'me@myhost.com',
  to => 'you@host.com',
  subject => 'The subject',
  plaintext => [$template, ':TT-scalar'],
  template_vars => {
   name => 'My Name',
   age => 20,
  },
 );

 # Create the plain text part of the email message using L<HTML::Template|HTML::Template> from a template file:

 plaintext => ['template.tmpl', ':HTML::Template'],

 # Create the plain text part of the email message using L<HTML::Template|HTML::Template> from a template from a scalar variable

 plaintext => [$template_content, ':HTML::Template-scalar'],
 
The HTML part of the email message can be created in exactly the same way.

  # Add an attachment created from a template file using TT:
  
   attachment => ['template.tt', 'generated_file_name.html', 'text/html', ':TT'],
   
 # Add an attachment created from a TT template from a scalar variable:
 
  attachment => [$template_content, 'generated_file_name.txt', 'text/plain', ':TT-scalar'],
  
 # Add an attachment created from a template file using L<HTML::Template|HTML::Template>:
 
  attachment => ['template.tmpl', 'generated_file_name.txt', 'text/plain', ':HTML::Template'],
  
  # Add an attachment created from a template from a scalar variable using L<HTML::Template|HTML::Template>:
  
   attachment => [$template_content, 'generated_file_name.html', 'text/html', ':HTML::Template-scalar'],

 # Add an attachment from a scalar variable, without using any templating system:
 
  attachment => [$file_content, 'generated_file_name.html', 'text/html', ':Scalar'],
  
Using the ":Scalar" as the last element of the arrayref makes it possible to create any type of file on the fly and add it as attachment to an email message. You can also add any type of file using templates, if the templating system used can create the type of file you want to add.

=head2 Advanced use of templates

If an email message should be created using more than a single templating system, all the templates can share the arguments from the C<template_args> hashref. For example if both L<Template-Toolkit|Template> and L<HTML::Template|HTML::Template> are used and we want to specify the path to the directory with templates, the C<template_args> parameter could include:

 template_args => {
  INCLUDE_PATH => '/path/to/TT/templates',
    path => '/path/to/HTML-Template/templates',
     },
     
     This is possible because the arguments used by these 2 templating systems are in this case different (C<path> and C<INCLUDE_PATH>). But if 2 templating systems that need to use the same argument are used and if that parameter should have a different value for each one, than it won't be possible to share all the parameters from C<template_args>.
     
     In that case, we could add a new element in the arrayref by specifying the C<template_args> hashref separately for each template:
     
 plaintext => ['template.tt', {INCLUDE_PATH => '/path/to/TT/templates'}, ':TT'],
 htmltext => ['template.tmpl', {path => '/path/to/HT/templates'}, ':HTML::Template'],
 attachment => ['template.tt', 'file.html', 'text/html', {INCLUDE_PATH => '/another/dir'}, ':TT'],
   
As you have seen, the C<template_args> hashref for each template is added as a penultimate element of the arrayref and it can contain the same elements as the main C<template_args> parameter.

The variables from the C<template_args> hashref overwrite the variables defined in the main C<template_args> hashref if it is used.

If more templates are used for creating an email message, possibly using more templating systems, all of the templates get the variables specified in the C<template_vars> hashref.

However, if 2 or more templates use a value with the same name, but that variable should have different values in different templates, you can also add a C<template_vars> hashref for each template, and overwrite the variables specified in the main C<template_vars> hashref.

This C<template_vars> hashref which is specified for each template is added in the arrayref before the C<template_args> hashref. If you need to add just a local C<template_vars> hashref but not a C<template_args> one, you need to use an empty hashref - {} in place of the C<template_args> hashref, like:

 plaintext => [
  'template.tt',
  {name => 'Your Name', age => 20},
  {INCLUDE_PATH => '/path/to/TT/templates'},
  ':TT'
 ],

 htmltext => [
  'template.tmpl',
  {name => 'Another name', address => '...'},
  {},
  ':HTML::Template'
 ],

 attachment => [
  'template.tt',
  'file.html',
  'text/html',
  {name => 'Something Else'},
  {INCLUDE_PATH => '/another/dir'},
  ':TT'
 ],

=head1 Using the module

After using the C<send()> function, the C<To:>, C<CC:> and C<BCC:> fields are cleared from the Mail::Builder::Simple object, so you can use the same object to send the same email to other recipients.

Here is an example:

 my $mail = Mail::Builder::Simple->new(from => 'me@myhost.com');

 $mail->send(
  to => 'you@host.com',
  subject => 'The subject',
  plaintext => 'The body of the message',
 );

 $mail->send(to => 'he@host2.com');
 $mail->send(to => 'she@host3.com');

The last 2 lines sent the message previously created. If you want to create an entirely new message, you should use the method C<new()> again.

=head1 DEPENDENCIES

L<Mail::Builder|Mail::Builder>, L<Email::Sender::Simple|Email::Sender::Simple>, L<Email::Valid|Email::Valid>, L<Module::Load|Module::Load>, L<Config::Any|Config::Any>

=head1 INCOMPATIBILITIES

Starting with the version 0.10, the module tries to keep the compatibility with the programs that were using previous versions of this module, because beginning with this version, the email messages will be sent using the module L<Email::Sender::Simple|Email::Sender::Simple> and not L<Email::Send|Email::Send> as before.

The possible incompatibilities could appear only in the way you use the C<mail_client> key. In the previous versions, you needed to use something like:

  mail_client => {
    mailer => 'SMTP',
    mailer_args => [Host => 'smtp.host.com'],
  },

This was the promoted style, although it was also possible to use:

  mail_client => {
    mailer => 'SMTP',
    mailer_args => {Host => 'smtp.host.com'},
  },

So you were also able to use a hashref instead of an arrayref for the mailer_args key.

Now the promoted style is the one that uses a hashref, although it is also possible to use the arrayref style if you want, so from this point of view it shouldn't be any incompatibilities.

As you might have seen, the SMTP host is now specified using the "host" key and not "Host" like in the previous versions. The "host" key is the one that should be used in the new programs, but the old "Host" key is also working.

If you wanted to access an SMTP server on a non-standard port in older versions, you needed to provide it in the form host:port. Now there is a key named "port" that you can use instead, like in the following example:

  mail_client => {
    mailer => 'SMTP',
    mailer_args => {host => 'smtp.host.com', port => 28},
  },

But you can still use the notation host: port like before if you want, as in:

  mailer_args => [Host => 'smtp.host.com:28'],

Some of the mailers that could be used with the older versions of this module like L<Email::Send::Gmail|Email::Send::Gmail> can't be used anymore but most of the features offered by them are also offered by similar C<Email::Sender::Transport::> modules.

If you found an untreated incompatibility, please tell me.

=head1 BUGS AND LIMITATIONS

If you find some, please tell me.

=head1 DIAGNOSTICS

=head1 SEE ALSO

L<Mail::Builder|Mail::Builder>, L<Email::Sender::Simple|Email::Sender::Simple>, L<Template-Toolkit|Template>, L<HTML::Template|HTML::Template>, L<Config::Any|Config::Any>

=head1 AUTHOR

Octavian Rasnita <orasnita@gmail.com>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
