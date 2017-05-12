<CsoundSynthesiser>
; This file is explained on p148 of the book "Csound Power" by Jim Aikin.
; It shows how to load a SoundFont into csound and play notes from it.
; It assumes you have run make_bank5, so that /tmp/Bank5.sf2 now exists.
<CsOptions>
-d -m0 -M0 -iadc -odac
</CsOptions>
<CsInstruments>
sr=44100
ksmps=64
nchnls=2
0dbfs=1

giEngine fluidEngine   ; start an engine
giSFnum fluidLoad "/tmp/Bank5.sf2", giEngine, 1
; fluidProgramSelect giEngine, icha1to16, giSFnum, ibank, ipatch0to127
fluidProgramSelect giEngine, 1, giSFnum, 5, 3
fluidProgramSelect giEngine, 2, giSFnum, 5, 1

instr 1,2   ; play a note, using p1 to choose a channel
ichan = p1
inote = p4
ivel = p5
fluidNote giEngine, ichan, inote, ivel
endin

instr 11   ; send cc1 mod-wheel to channel 2
kmod linsegr 0, p3, 127, p3, 0
kmod = int(kmod)
fluidCCk giEngine, 2, 1, kmod
endin

instr 99  ; capture Engine's output and play it
iamp = p4
asigL, asigR fluidOut giEngine
asigL = asigL * iamp
asigR = asigR * iamp
outs asigL, asigR
endin

</CsInstruments>
<CsScore>

t0 100
i1 0  7  48 60   ; play some notes on channel 1
i1 0  7  52
i1 0  7  55
i1 0 0.8 60 100
i1 1 0.8 64 70
i1 2  .  67 75
i1 3  .  64 80
i1 4  3  60 80
i2 0 0.333  72 60   ; play some notes on channel 2
i2 +  .     71
i2 +  .     72
i2 +  .     67
i2 +  .     69
i2 +  .     71
i2 +  4     72

i99 0 8 7   ; capture the output and play it

i11 0.7 2.5

</CsScore>
</CsoundSynthesiser>
