# NAME

MHA::AWS - A support script for "MySQL Master HA" running on AWS

# SYNOPSIS

    $ mhaws [subcommand] --interface_id=ENI-id [... args passed by MHA]
    $ mhaws [subcommand] --route_table_id=[RouteTable-id] --vip=[master VIP] [... args passed by MHA]

    required arguments:
      1. failover method is ENI attach/detach
        --interface_id=[ENI-id for master VIP]

      2. failover method is RouteTable change destination
        --route_table_id=[RouteTable-id]
        --vip=[master VIP]

    subcommand:
      master_ip_failover
      master_ip_online_change
      shutdown


    /etc/masterha_default.cnf

    [server default]
    master_ip_failover_script=mhaws master_ip_failover --interface_id=eni-xxxxxxxx
    master_ip_online_change_script=mhaws master_ip_online_change --interface_id=eni-xxxxxxxx
    shutdown_script=mhaws shutdown --interface_id=eni-xxxxxxxx

# DESCRIPTION

MHA::AWS is a support script for "MySQL Master HA" which running on Amazon Web Service.

# REQUIREMENTS

- EC2 instance's "Name" tags must be resolved as DNS name in internal.
- root user must be allowed to ssh login between each MySQL instances.
- aws-cli is installed and available.

## Failover method = ENI attach/detach

- One ENI (Elastic Network Interface) must be attached to the MySQL master instance. Clients accesses for the ENI's IP address.

## Failover method = VPC route table rewriting

- Prepare a VIP address in your VPC.
- All MySQL hosts(master, slaves) can handle the VIP.
- Clients accesses for the VIP address.

# FAILOVER FLOW

- 1 MHA detect master failure.
- 2 "mhaws master\_ip\_failover --command stop", ENI will be detached from the old master instance.
    - (ENI) ENI will be detached from the old master instance.
    - (Route table) Route to VIP will be removed from VPC route table.
- 3 "mhaws shutdown --command (stopssh|stop)", Old master mysqld process will be killed (if ssh connection is available). Or old master instance will be stopped via AWS API (if ssh connection is NOT available).
- 4 MHA will elect the new master and set up replication.
- 5 "mhaws master\_ip\_failver --command start", ENI will be attached to the new master instance.
    - (ENI) ENI will be attached to the new master instance.
    - (Route table) Route to VIP will be set to new master instance.

# SEE ALSO

[AWS::CLIWrapper](https://metacpan.org/pod/AWS::CLIWrapper), [https://code.google.com/p/mysql-master-ha/](https://code.google.com/p/mysql-master-ha/)

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
