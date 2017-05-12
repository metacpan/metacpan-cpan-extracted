<CsoundSynthesizer>
<CsOptions>
; -d -m229 -o dac -T -F midifile.mid
-d -rtmidi=alsa -m0 -MPro -iadc -odac
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 128
nchnls = 2
0dbfs = 1

; Example by Istvan Varga

; disable triggering of instruments by MIDI events

ichn = 1
lp1:
        massign   ichn, 0
        loop_le   ichn, 1, 16, lp1
        pgmassign 0, 0

; initialize FluidSynth

gifld   fluidEngine
gisf2   fluidLoad "/tmp/Bank5.sf2", gifld, 1
giBank = 5

; k-rate version of fluidProgramSelect

opcode fluidProgramSelect_k, 0, kkkkk
  keng, kchn, ksf2, kbnk, kpre xin
        igoto     skipInit
  doInit:
        fluidProgramSelect i(keng), i(kchn), i(ksf2), giBank, i(kpre)
        printf "channel %d set to bank %d patch %d\n", 1, kchn,giBank,kpre
        reinit    doInit
        rireturn
  skipInit:
endop

instr 1
  ; initialize channels
  kchn  init 1
  if (kchn == 1) then
lp2:
        fluidControl gifld, 192, kchn - 1, 0, 0
        fluidControl gifld, 176, kchn - 1, 7, 100
        fluidControl gifld, 176, kchn - 1, 10, 64
        loop_le   kchn, 1, 16, lp2
  endif

  ; send any MIDI events received to FluidSynth
nxt:
  kst, kch, kd1, kd2 midiin
  if (kst != 0) then
    if (kst != 192) then
        fluidControl gifld, kst, kch - 1, kd1, kd2
    else
        fluidProgramSelect_k gifld, kch - 1, gisf2, 0, kd1
    endif
      kgoto nxt
  endif

  ; get audio output from FluidSynth
  aL, aR fluidOut gifld
        outs      aL, aR
endin

</CsInstruments>
<CsScore>

i 1 0 3600
e

</CsScore>
</CsoundSynthesizer> 
