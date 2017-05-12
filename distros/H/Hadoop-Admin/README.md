# NAME

Hadoop::Admin - Module for administration of Hadoop clusters

# SYNOPSIS

    use Hadoop::Admin; 

    my $cluster=Hadoop::Admin->new({
      'namenode'          => 'namenode.host.name',
      'jobtracker'        => 'jobtracker.host.name',
    });

    print $cluster->datanode_live_list();



# DESCRIPTION

This module connects to Hadoop servers using http.  The JMX Proxy
Servlet is queried for specific mbeans.

This module requires Hadoop the changes in
https://issues.apache.org/jira/browse/HADOOP-7144.  They are available
in versions 0.20.204.0, 0.23.0 or later.

# INTERFACE FUNCTIONS

## new ()

- Description

Create a new instance of the Hadoop::Admin class.  

The method requires a hash containing at minimum the namenode's, and
the jobtracker's hostnames.  Optionally, you may provide a socksproxy
for the http connection.

Creation of this object will cause an immediate querry to both the
NameNode and JobTracker.

- namenode => <hostname>
- jobtracker => <hostname>
- socksproxy => <hostname>
- Returns newly created object.

## get_namenode ()

- Description

Returns the JobTracker from instantiation

## get_namenode ()

- Description

Returns the JobTracker from instantiation

## get_namenode ()

- Description

Returns the Socks Proxy from instantiation

## datanode_live_list ()

- Description

Returns a list of the current live DataNodes.

- Return values

Array containing hostnames.

## datanode_dead_list ()

- Description

Returns a list of the current dead DataNodes.

- Return values

Array containing hostnames.

## datanode_decom_list ()

- Description

Returns a list of the currently decommissioning DataNodes.

- Return values

Array containing hostnames.

## nodemanager_live_list ()

- Description

Returns a list of the current live NodeManagers.

- Return values

Array containing hostnames.

## tasktracker_live_list ()

- Description

Returns a list of the current live TaskTrackers.

- Return values

Array containing hostnames.

## tasktracker_blacklist_list ()

- Description

Returns a list of the current blacklisted TaskTrackers.

- Return values

Array containing hostnames.

## tasktracker_live_list ()

- Description

Returns a list of the current graylisted TaskTrackers.

- Return values

Array containing hostnames.

# KNOWN BUGS

None known at this time.  Please log issues at: 

https://github.com/cwimmer/hadoop-admin/issues

# AVAILABILITY

Source code is available on GitHub:

https://github.com/cwimmer/hadoop-admin

Module available on CPAN as Hadoop::Admin:

http://search.cpan.org/~cwimmer/

# AUTHOR

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

    The (three-clause) BSD License

The BSD License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution. 

    * Neither the name of Charles A. Wimmer nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.