# HV::Monitor

Provides a LibreNMS style JSON SNMP extend for monitoring HV
info. Currently supported ones are as below.

- FreeBSD: CBSD+bhyve
- Linux: Libvirt+QEMU

## Installation

FreeBSD...

```
pkg install p5-App-cpanminus p5-JSON p5-MIME-Base64 p5-Gzip-Faster
cpanm HV::Monitor
```

Debian...

```
apt-get install zlib1g-dev cpanminus libjson-perl
cpanm HV::Monitor
```

## Usage

The cron+snmpd setup is needed as even if you use sudo to make sure
snmpd can run it, this usual time it takes this to run will result in
in a time out.

For cron...

```
*/5 * * * * /usr/local/bin/hv_monitor > /var/cache/hv_monitor.json -c 2> /dev/null
```

For snmpd...

```
extend hv-monitor /bin/cat /var/cache/hv_monitor.json
```

### FLAGS

#### -b backend

The backend to use.

Defaults are as below.

| OS      | Module  |
|---------|---------|
| FreeBSD | CBSD    |
| Linux:  | Libvirt |

#### -c

Compress the output using gzip and base64 encoded so it can be
transmitted via SNMP with out issue.

## JSON Return

These are all relevant to `.data` in the JSON.

- .VMs :: Hash of the found VMs. VM names are used as the keys. See
  the VM Info Hash Section for more information.
- .totals :: Hash of various compiled totals stats. This does not
  include the disks or ifs hashes. The relevant stats are migrated
  from the the relevant hash to the VM info hash to finally the totals
  hash.

### VM Info Hash

- mem_alloc :: Allocated RAM, MB
- cpus :: Virtual CPU count for the VM.
- pcpu :: CPU usage percentage.
- pmem :: Memory usage percentage.
- os_type :: OS the HV regards as the VM as using.
- ip :: Primary IP the HV regards the VM as having. Either blank, an
  IP, or 'DHCP'.
- status_int :: Integer of the current status of the VM.
- console_type :: Console type, VNC or Spice.
- console :: Console address and port.
- snaps_size :: Total size of snapshots. Not available for libvirt.
- snaps :: The number of snapshots for a VM.
- ifs :: Interface hash. The name matches `/nic[0-9]+/`.
- rbytes :: Total write bytes.
- wbytes :: Total read bytes.
- etimes :: Elapsed running time, in decimal integer seconds.
- cow :: Number of copy-on-write faults.
- majflt :: Total page major faults.
- minflt :: Total page minor faults.
- nice :: Proc scheduling increment.
- nivcsw :: Total involuntary context switches.
- nswap :: Total swaps in/out.
- nvcsw :: Total voluntary context switches.
- inblk :: Total blocks read.
- oublk :: Total blocks wrote.
- pri :: Scheduling priority.
- rss :: In memory size in Kbytes.
- systime :: Accumulated system CPU time.
- usertime :: Accumulated user CPU time.
- vsz :: Virtual memory size in Kbytes.
- disks :: A hash of disk info.
- rbtyes :: Total bytes read.
- rtime :: Total time in ms spent on reads.
- rreqs :: Total read requests.
- wbytes :: Total bytes written.
- wreqs :: Total write requests.
- ftime :: Total time in ms spent on flushes.
- freqs :: Total flush requests.
- disk_alloc :: Number of bytes allocated to for all disks.
- disk_in_use :: Number of bytes in use by by all disks.
- disk_on_disk :: Number of bytes in use on all disks. For qcow, this
  will be larger than in_use as the file includes snapshots
- coll :: Packet collisions.
- ibytes :: Input bytes.
- idrop :: Input packet drops.
- ierrs :: Input errors.
- ipkgs :: Input packets.
- obytes :: Output bytes.
- odrop :: Output packet drops.
- oerrs :: Output errors.
- opkts :: Output packets.

### Interface Hash

The interface hash keys are as below.

- if :: Interface the device is mapped to.
- parent :: Bridge or the like the device if is sitting on.
- coll :: Packet collisions.
- ibytes :: Input bytes.
- idrop :: Input packet drops.
- ierrs :: Input errors.
- ipkgs :: Input packets.
- obytes :: Output bytes.
- odrop :: Output packet drops.
- oerrs :: Output errors.
- opkts :: Output packets.

Status integer mapping is as below. Not all HVs will support all of
these.

| State       | Int | Desc                                |
|-------------|-----|-------------------------------------|
| NOSTATE     | 0   | no state                            |
| RUNNING     | 1   | is running / generic on             |
| BLOCKED     | 2   | is blocked on resource              |
| PAUSED      | 3   | is paused by user                   |
| SHUTDOWN    | 4   | is being shut down                  |
| SHUTOFF     | 5   | is shut off                         |
| CRASHED     | 6   | is crashed                          |
| PMSUSPENDED | 7   | suspended by guest power management |
| OFF         | 8   | Generic off                         |
| MAINTENANCE | 9   | Maintenance                         |
| UNKNOWN     | 10  | Unknown                             |

### Disk Hash

Disk hash keys is as below.

- alloc :: Number of bytes allocated to a disk.
- in_use :: Number of bytes in use by the disk.
- on_disk :: Number of bytes in use on the disk. For qcow, this will
  be larger than in_use as the file includes snapshots
- rbtyes :: Total bytes read.
- rtime :: Total time in ms spent on reads.
- rreqs :: Total read requests.
- wbytes :: Total bytes written.
- wreqs :: Total write requests.
- ftime :: Total time in ms spent on flushes.
- freqs :: Total flush requests.
