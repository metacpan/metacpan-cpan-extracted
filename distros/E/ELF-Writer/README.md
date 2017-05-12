## WHAT IS THIS?

This module allows you to write ELF ( [Executable and Linkable Format][WikipediaELF] )
files with nothing but pure perl!  Combined with [CPU::x86_64::InstructionWriter][InstWriter]
you can build your own binaries without touching gcc or binutils or any other megalithic
toolchain.

Implementing a compiler is left as an exercise for the reader.

## THAT SOUNDS... UGLY

Actually it's fairly painless, if your needs are simple.

```
  my $elf= ELF::Writer::Linux_x86_64->new(
    type => 'executable',
    segments => [{
      virt_addr   => 0x10000,
      data        => $my_machine_code,
    }],
    entry_point => 0x10000
  );
  $elf->write_file("my_executable");
```

## WHOSE FAULT IS THIS?

I, Michael Conrad, accept full responsibility for this blatant abuse of technology.

## BUT WHY, DAMMIT? WHY?

If you have to ask why, you are not a member of the intended audience.
Please go on about your business and accept my apologies for this distraction.

## THAT'S CRAZY... BUT UM, WHERE CAN I LEARN ABOUT THIS?

Brian Raiter has a very nice writeup about [diving into the details of ELF][TeensyELF]
which I found intriguing and educational, and refer back to any time I need to remember
some of this stuff.

Once you see what he's doing, you will understand the inspiration for this module.


----

Also, Thanks to Bob Zimbinski (author of [TTY Quake][] ) for the original
inspiration behind my various abuses of technology.

[WikipediaELF]: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
[InstWriter]: https://github.com/nrdvana/perl-CPU-x86_64-InstructionWriter
[TeensyELF]: http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
[TTY Quake]: https://web.archive.org/web/20100127215948/http://webpages.mr.net/bobz/ttyquake/
