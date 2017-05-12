NAME
    Mail::Qmail::Queue::README - Overview of Mail::Qmail::Queue

SYNOPSIS
    "Mail::Qmail::Queue" is a small collection of modules to help with
    talking to qmail-queue and/or writing replacements for it. It also
    contains some handy command-line tools for testing "qmail-queue" or its
    replacements.

    Writing "qmail-queue" replacements is a popular way to replace parts of
    the functionality of the functionality of qmail
    (<http://cr.yp.to/qmail.html>). Because of qmail's modular style, it's
    easy to swap out individual components to change their behavior.

    This is commonly done with Bruce Guenter's QMAILQUEUE patch
    (<http://www.qmail.org/top.html#qmailqueue>), also included in netqmail
    (<http://www.qmail.org/netqmail/>). This patch lets you override the
    standard "qmail-queue" program by setting the environment variable
    "QMAILQUEUE". It can also be done by renaming the original
    "qmail-queue", installing your script in its place, and having your
    script call the renamed "qmail-queue" to inject the message.

MODULES
    Mail::Qmail::Queue::Message
        Easy-to-use module for sending and receiving messages.

    Mail::Qmail::Queue::Receive::Envelope
        Receive the envelope of a message.

    Mail::Qmail::Queue::Receive::Body
        Receive the body of a message.

    Mail::Qmail::Queue::Send
        Send a message body and envelope.

    Mail::Qmail::Queue::Error
        Utilities for handling errors.

UTILITIES
    These utilities are useful for debugging and testing.

    qqtest
        Test a "qmail-queue" replacement.

    qqdump
        Dump the information sent to a "qmail-queue" replacement.

BUGS
    By convention, Perl modules start with an upper-case letter. Therefore,
    this module is called "Mail::Qmail::Queue", even though that's not the
    proper capitalization for "qmail".

