# NAME

Email::Stuffer::TestLinks - validates links in HTML emails sent by 
Email::Stuffer>send_or_die()

# VERSION

version 0.010

# SYNOPSIS

    use Email::Stuffer::TestLinks;

# DESCRIPTION

When this module is included in a test, it parses HTML links (<a href="xyz"...) 
in every email sent through Email::Stuffer->send_or_die(). Each URI must get a 
successful response code (200 range) and the returned pagetitle must not contain
'error' or 'not found'.