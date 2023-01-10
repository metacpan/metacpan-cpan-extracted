#!/usr/bin/env python3

# Will print:
#Protein Sequence:       *   D   A   R   W   I   N   *  
#DNA Sequence:          TAA-GAT-GCT-CGT-TGG-ATT-AAT-TAA

dna_sequence = ""
protein_sequence = ""
protein_sequence = "*DARWIN*"
print ("Protein Sequence:     ", "".join([" %s  " % i for i in protein_sequence]))

# codon table
code = {
    'A': 'GCT', 
    'C': 'TGT', 
    'D': 'GAT',
    'E': 'GAA',
    'F': 'TTT',
    'G': 'GGT',
    'I': 'ATT',
    'H': 'CAT',
    'K': 'AAA',
    'L': 'TTA',
    'M': 'ATG',
    'N': 'AAT',
    'P': 'CCT',
    'Q': 'CAA',
    'R': 'CGT',
    'S': 'TCT',
    'T': 'ACT',
    'V': 'GTT',
    'W': 'TGG',
    'Y': 'TAT',
    '*': 'TAA' 
}
for i in range(0, len(protein_sequence)):
    dna_sequence = dna_sequence + code[protein_sequence[i]] + "-"

print ("DNA Sequence:         ", dna_sequence[:-1])
