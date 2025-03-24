# Name
    Mail:Alias::LocalFile

    Resolve email aliases from a locally maintained aliases file in addition to the system-wide aliases file 
# Version

    version 0.01

# Synopsis
```
    use Mail::Alias::LocalFile;

    my $resolver   = Mail::Alias::LocalFile->new(aliases => $aliases);
    my $result     = $resolver->resolve_recipients($intended_recipients);
    my $recipients = $result->{recipients};
    my $warning    = $result->{warning};

    - $aliases is a hashref of a local aliases file

    - $intended_recipients is a list or arrayref of addressees 
      (i.e. mary@example.com, joe, group2)

    - $recipients is the comma separated list of email addressees 
      needed by you email client code

    - $warning identifies problems encountered (if any)

    See below and use perldoc LocalFile.pm for additional documentation
```

# Description

This module allows the use of a locally maintained aliases file in addition to the
aliases file provided by the Mail Transfer Agent (MTA). This module reduces dependence 
on the system wide MTA aliases file. You can avoid the use of the system aliases entirely 
or you can use some of them to supplement your local maintained aliases. This module is 
useful when you want to maintain your own email aliases file, with limited use of the 
system wide aliases file.

The type of local file holding the alias definitions is up to your application. File
types such as JSON, YAML, XML, INI and many others could be used, provided the file
loads an appropriately structured hashref.

# Rational
This module allows the use of a locally maintained aliases file in addition to using the 
aliases file used by the MTA. This is beneficial for several reasons:
- The MTA aliases file may not be available to you because editing it is restricted by corporate policy
- The MTA aliases file is shared and you want to avoid conflicting alias names already in use by others
- The MTA is being edited by persons not affliated with your application and their actions could affect your emails
- You want control of your own aliases in a file not availble to others but also have access to system aliases when needed

# Input
In your application, create a new resolver object - using Moo style named parameters

- my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
  
Where inputs are:
- $aliases is a hash_ref of key/value pairs holding the entire contents of your locally maintained aliases file

# Output
- my $result = $resolver->resolve_recipients($intended_recipients);
- $intended_recipients is an array_ref holding the email addressses and aliases of the intended email recipients
- Where $result is a hash_ref as shown below:
```
    my $recipients           = $result->{recipients};
    my $warning              = $result->{warning};
    my $alias_file_contents  = $result->{aliases};
    my $original_input       = $result->{original_input};
    my $processed_aliases    = $result->{processed_aliases};
    my $uniq_email_addresses = $result->{uniq_email_addresses};
    my $expanded_addresses   = $result->{expanded_addresses};

```
Output includes all of the following to use as desired:
- $recipients is the desired email aliases expansion like 
  "john\@company.com,joe\@example.com,mary\@example.com"
- $warnings is an array_ref holding issues encountered, like a malformed email
  address or misspelled alias
- $alias_file_contents is the entire contents of the local alias file, possibly
  for troubleshooting
- $original_input is an array_ref holding the $intended_recipients, 
  for troubleshooting
- $processed_aliases is a hash_ref identifying each alias that was expanded to 
  email addresses, for troubleshooting
- $expanded_addresses is an array_ref built as each alias is expanded, which 
  can include duplicate email addresses
- $uniq_email_addresses is an array_ref like $expanded_addresses but with the 
  duplicates (if any) removed
  
$recipients is the same content as $uniq_email_addresses, except it is held as
the comma separated string most likely desired by your email code

# Dependencies
```
The Mail::Alias::LocalFile.pm package uses:
- use Moo; 
- use namespace::autoclean;
- use Email::Valid;
- use Scalar::Util qw(reftype);
- use Types::Standard qw(ArrayRef HashRef Str);
```

This module is NOT dependent on the (excellent) Mail::Alias module. Mail::Alias is 
designed to read, write, update and convert between the Sendmail, Ucbmail and Binmail 
MTA alias file formats. This module has a diffferent purpose, which is to avoid reliance on 
the MTA alias file entirely or just to the extent desired.

# INSTALLATION
```
To install this module:
   perl Makefile.PL
   make
   make test
   make install
```

# Assumptions:
- The application can load a locally maintained aliases configuration file
- The aliases file can use any practical format such as YAML, JSON, XML, INI or similar
- When the entire aliases file is loaded, the data is held in a Perl hash reference 
- Each hash key is the name of an alias
- The values, when loaded, are seen as strings or arrays. (Hashes are not supported as values)
- Values are combinations of one or more email addresses and alias names, just as is customary in the MTA system aliases file
- The script or application, when sending outbound email, expects recipients to be a comma separated list of email addresses, ie joe\@example.com,mary\@company.com,mike\@sample.com
  
# Sample Aliases Files:
Sample configuration files (YAML and JSON formatted) are provided as examples of locally 
maintained aliases files that load as a hash_ref containing acceptable keys and values. 
They intentionally use various (unlikely) types of comma and space separation to demonstrate the 
flexibility allowed in value formatting. They hold examples of the 'mta_' prefix used 
to include aliases from the system MTA aliases file. Some sample files intentionally contain 
circular references for aliases, for illustrative purposes.

Sample scripts are included to demonstrate usage and capabilities. Use perldoc for POD descriptions.

# Limitations and Applicability
- This module converts aliases to email addresses using a local file you 
  manually edit and maintain. The more complex capabilities of a MTA system 
  wide aliases file (such as sending email to files or passing through pipes) 
  still require the use of that file. When needed, those capabilities can be 
  accessed from entries in your local file.
- This module resolves email addresses from aliases from the hash_ref provided 
  when you load your local aliases file. It does not create or update the file. 
  You edit your local file manually, just like the system mail aliases file.
- YAML and JASON formatted sample alias files are provides because they have an 
  easy to maintain layout. However, you can use any format you like as long as 
  it can be loaded as a hash reference that contains keys with values that load
  as strings or arrays.

# Regular aliases and mta_ prefix aliases
  - **Regular aliases**
    
    Just like in the system aliases file, values in the local alias file can 
    consist of one or more email addresses and locally defined aliases 
    representing email addresses. Locally defined aliases listed as values are
    expanded without the use of the system aliases file. For example, an alias 
    named 'sales' is expanded to the email addresses assigned to the 'sales' 
    alias defined in the local aliases file. If there is also a sales alias 
    defined in the system aliases file, it is not used. Except as described for
    the mta_ prefix, the local alias definition supersedes the system file 
    definition.

  - **mta_ prefixes**

    The 'mta_' prefix is used within a local alias file **value** to allow 
    aliases to be expanded by the MTA instead of being expanded locally. 
    For example, assume a **value** in the local aliases file hold alias 
    'mta_sales'. This module recognizes the 'mta_' prefix, removes the prefix,
    and allows the remainder (in this case sales) to pass through for eventual
    expansion by the MTA using the system aliases file.

    'mta_' prefixed aliases can be used in conjunction with the local file 
    aliases. Assume the sales alias in the system file includes two email 
    addresses for senior managers joe and mary:

        sales: joe@hq.company.com, mary@hq.company.com  (In the system aliases file)

    The local alias file could hold this entry:

        sales: billy@local.company.com, mta_sales   

    **(Important: mta_ prefixes are never used as local alias file keys, only within values)** 

    The module would expand the local alias (picking up billy\@local.company.com
    as a recipient) and strip the prefix from mta_sales. The 'To: ' section of 
    your email header would receive 'billy\@local.company.com,sales'.  When the 
    email is processed by the MTA, sales is expanded using the system aliases 
    file to include joe and mary's email addresses. The three recipients become 
    'billy\@local.company.com,joe\@hq.company.com,mary\@hq.company.com'

    To send email to a local user mail account on the server, create an alias 
    for the username in the local aliases file and assign a value that uses the
    mta_ prefix. For a user with login name INC0027 the YAML formatted local 
    aliases file entry could be:

    INC0027: mta_INC0027

    The 'mta_' prefix can also be used to take advantage of advanced aliasing 
    features not supported by the local aliases file, such as appending email 
    to files, or using pipes to execute commands. As long as the alias is 
    defined in the system aliases file, the local alias file can use a 
    corresponding mta_ prefix to incorporate it.

    The 'mta_' prefix cannot be used as prefix to a key in the local aliases.  
    Its use is restricted to inclusion as part of a value. In the local aliases
    file:
    
        mta_postmaster: postmaster (**NOT ALLOWED**. The mta_ prefix cannot be used as a local alias key)
    
        postmaster: mta_postmaster (Correct. Becomes 'postmaster as seen by the system file)

# Functionality:
Methods are described within the POD.  (perldoc LocalFile.pm)

Method provided functionality includes:
- Malformed email addresses are skipped
- References to non-existent aliases are skipped
- Each alias is only expanded once, so circular references are tolerated by suppression.
- Warnings messages when encountering the above issues are captured 
- Duplicated email recipients are removed
- Basic email address format validity is determined through Email::Valid->address
- Converts all email addresses to lower case lettering
- Utilizes the system wide MTA aliases file when the 'mta_' prefix is attached 
  to a value in the local aliases file

# Detect and report circular references
LocalFile.pm is generally tolerant of circular alias references within the 
local aliases file. An attempt is made to avoid a loop by only expanding each
alias once. Nevertheless, good practice necessitates removing circular 
references whenever possible. Screen for circular references in the local 
aliases file is follows:

```
$resolver = Mail::Alias::LocalFile->new(aliases => $aliases);
@circular_refs = $resolver->detect_circular_references($aliases);

if ($circular_refs[0]) {
    print "WARNING: Circular references detected:\n";
    foreach my $circ_ref_item (@circular_refs) {
        print "  $circ_ref_item\n";
    }
}
```
# Issues
- https://github.com/usna78/Mail-Alias-LocalFile/issues

# Copyright
Copyright 2025, Dwight R. Brewer (Russ), All Rights Reserved

# LICENSE
GNU LESSER GENERAL PUBLIC LICENSE Version 2.1, February 1999. See included LICENSE file.

# Author
Russ Brewer <rbrew@cpan.org>


