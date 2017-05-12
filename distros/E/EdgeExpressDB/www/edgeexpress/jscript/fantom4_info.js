/*  EdgeExpressDB [eeDB] system
 *  copyright (c) 2007-2009 Jessica Severin, RIKEN OSC
 *  All rights reserved.
 * 
 *  You may distribute under the terms of either the 
 *  GNU General Public License version 3 or the Perl Artistic License 1.0
 *  For details, see 
 *        http://www.gnu.org/licenses/gpl-3.0.txt
 *        http://www.perlfoundation.org/artistic_license_1_0
 *
 *--------------------------------------------------------------------------*/

function infoToolTip(content, width) {

  if(infoToolTip.arguments.length < 1) { // hide 
    if(ns4) toolTipSTYLE.visibility = "hidden";
    else toolTipSTYLE.display = "none";
    toolTipWidth=300;
  }
  else { // show

    toolTipWidth=width;
    var object_html = "<div style=\"text-align:left; font-size:10px; font-family:Verdana,arial,helvetica,sans-serif; "+
                      "width: " + width +"px; z-index:100; "+
                      "background-color:lavender; border:inset; padding: 3px 3px 3px 3px;"+
                      "\">";
    object_html += content;
    object_html += " </div>";

    if(ns4) {
      toolTipSTYLE.document.write(object_html);
      toolTipSTYLE.document.close();
      toolTipSTYLE.visibility = "visible";
    }
    if(ns6) {
      document.getElementById("toolTipLayer").innerHTML = object_html;
      toolTipSTYLE.display='block'
    }
    if(ie4) {
      document.all("toolTipLayer").innerHTML=object_html;
      toolTipSTYLE.display='block'
    }
  }
}


function TFBS_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">TFBS predictions</div>";
  content += "<p><span style=\"font-weight: bold;\">TFBS EDGES:</span> Evolutionarily conserved Transcription factor binding sites are predicted using MOTEVO with a set of non-redundant matrices (combining JASPAR, TRANSFAC and a small set of de-novo motifs trained on ChIP-chip datasets).</p>";
  content += "<p><span style=\"font-weight: bold;\">TFBS WEIGHTS:</span> The weights on TFBS edges are 'response values', these are central to the FANTOM4 analysis and basically say how well the expression of each LEVEL2 promoter responds to (or matches) the motif activity for that factor (eg. MYB motif activity decreases as the cells differentiate and PRTN3 a known (and predicted) target of MYB is down-regulated, hence it has a high response weight of 14.125). We recommend to users wishing to validate sites, response weights >1.5 are more reliable. For more detail on TFBS prediction and motif activity please refer to the FANTOM4 manuscript (Suzuki et al. 2009).</p>";
  infoToolTip(content, 400);
}


function ChIP_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">ChIP</div>";

  content += "<p><span style=\"font-weight: bold;\">ChIP EDGES:</span> The FANTOM4 consortium generated chromatin immunoprecipitation on chip data for SPI1 and SP1, for these factors, a peak of binding within 1kb of a promoter is considered positive evidence for an edge between these factors and the target gene. Public ChIP-chip and ChIP-seq datasets were also incorporated, for these we relied on the primary publication\'s definition of positive binding, and we include a PubMed link back to the corresponding citation.</p>"; 

  content += "<p><span style=\"font-weight: bold;\">ChIP WEIGHTS:</span> The weights used here are the number of experiments this TF has been observed binding at the target gene\'s promoter (ie. a weight of 4, means it has been observed in 4 separate ChIP-chip experiments).</p>";

  infoToolTip(content, 400);
}


function miRNA_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">miRNA</div>";

  content += "<p><span style=\"font-weight: bold;\">miRNA EDGES:</span> miRNA to target transcript predictions were downloaded from the EIMMO prediction server (http://www.mirz.unibas.ch/ElMMo2/). Edges are then drawn to the corresponding Entrez Gene.</p>";

  content += "<p><span style=\"font-weight: bold;\">miRNA WEIGHTS:</span> Weights provided are the prediction strengths from the EIMMO software.</p>";

  infoToolTip(content, 300);
}


function perturbation_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">Perturbation</div>"; 

  content += "<p><span style=\"font-weight: bold;\">PERTURBATION EDGES:</span> siRNA knockdown(KD) of 52 transcription factors(TF) and over-expression of 12 miRNAs was used to identify TFs and miRNAs involved in THP-1 differentiation and maintenance of the undifferentiated state. Affected genes were assessed by Illumina microarrays 48 hours post transfection. The array data was quantile normalized and compared to negative control siRNAs and pre-miRNAs to identify genes that are specifically perturbed in response to the TF/miRNA.</p>";

  content += "<p><span style=\"font-weight: bold;\">PERTURBATION WEIGHTS:</span> The perturbation edges displayed in EEDB are stringently filtered, by log fold change >=1/<=-1 and B-statistic >=2.5. A positive log FC means the transcript is induced upon knockdown of the siRNA or over-expression of the miRNA. A negative log FC means the transcript is down-regulated in response to the perturbation (eg. CD14 is strongly induced upon MYB KD and has a log FC of 6.8, whereas vitrin is strongly repressed upon MYB KD and has a log FC of -4.0).</p>";

  infoToolTip(content, 700);
}


function other_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">Other</div>"; 

  content += "<p><span style=\"font-weight: bold;\">OTHER EDGES:</span> This section contains additional nodes linked to this gene. This section includes published protein-DNA edges, and is also used to manage transcripts (accession numbers), microarray probes and Level3 promoters associated with a given gene (ie. belongs-to relationships).</p>";
  content += "<p>For the published protein-DNA edges we include a small manuscript icon which can be clicked on and will take the user to the corresponding PubMed citation.</p>";
  content += "<div style='margins: 8px 0px 4px 0px;'><span style=\"font-weight: bold;\">OTHER WEIGHTS:</span> Weights for this section are set to a default of 1.</div>";

  infoToolTip(content, 400);
}


function ppi_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">Protein-protein interactions</div>";

  content += "<p><span style=\"font-weight: bold;\">PROTEIN-PROTEIN EDGES:</span> The protein-protein interactions currently displayed in EEDB are from transcription factor - transcription factor interactions only and are harvested from a number of public protein-protein interaction sources including DIP, BIND and HPRD (which is shown in the source).</p>";
  content += "<div style='margins: 8px 0px 8px 0px;'><span style=\"font-weight: bold;\">PROTEIN-PROTEIN WEIGHTS:</span> Weights are currently set to a default value of 1.</div>";

  infoToolTip(content, 600);
}


function promoter_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">CAGE DEFINED PROMOTERS</div>";

  content += "<p><span style=\"font-weight: bold;\">PROMOTER LEVELS:</span> For FANTOM4 we developed three levels to describe the relationship between individual transcription start sites (TSS), promoters and promoter regions. Individual TSS are referred to as level 1 (L1), nearby TSSs positions whose expression profiles are the same up to measurement noise are clustered into promoters (L2) and adjacent promoters that are within 400bp of each other are condensed into 'promoter regions' (L3). For further details on promoter levels please refer to the FANTOM4 main manuscript (Suzuki et al. 2009).</p>";

  content += "<p>P1<sup>L3</sup> corresponds to a level 3 promoter region of a gene which can contain multiple level 2 promoters (eg. Gene<sup>L2.1</sup> and Gene<sup>L2.2</sup>).  Note: TFBS predictions are done per level3, BUT response weight is calculated for each level 2 promoter</p>";

  content += "<p>Upon mouse-over the promoter ID [of the form L3_chr21_+_39099722] will be displayed. If the user clicks on this, it will open a genome browser page focused on the promoter region (-300 +100), displaying the promoters and the TFBS predicted in that region. This can be used to extract individual sites for ChIP and EMSA validation experiments.</p>";

  infoToolTip(content, 500);
}


function pub_protein_dna_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">PUBLISHED PROTEIN DNA</div>";

  content += "<p><span style=\"font-weight: bold;\">PUBLISHED PROTEIN DNA EDGES:</span> For the published protein-DNA edges we include a hyperlink to the corresponding PubMed citation.</p>";

  content += "<p><span style=\"font-weight: bold;\">PUBLISHED PROTEIN DNA WEIGHT:</span> By default set to 1.</p>";

  infoToolTip(content, 400);
}


function subnet_view_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">THE SUBNET VIEW</div>";

  content += "<div style='margin: 8px 0px 8px 0px;'>The subnet view allows for one to input a list of gene and/or miRNA names as nodes in a graph. The system will search for all matching connecting edges within that set of nodes based on user selectable edge filters.</div>";

  content +="<div style=\"color: steelblue; font-size:12px; font-weight: bold; margin: 0px 0px 4px 0px;\">INTERFACE:</div>";

  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">NODE SELECTION:</span> Users enter Entrez genes and mirbase microRNA IDs into the text box</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">PRIMARY EDGE TYPES:</span> The system allows for simple logic by providing two edge sets (primary and secondary). If only edges in set1 are selected then a simple search is performed.</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">SECONDARY EDGE TYPES:</span> If edges from both sets are selected the search is performed for genes that are connected by BOTH lines of evidence (eg. TFBS prediction in set 1 and perturbation or CHIP in set2), this can be used to prune TFBS predictions to only those for which there is some experimental support.</div>";
//  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">EXPAND NEIGHBOURS:</span> Warning this is currently slow. It is used to fluff out a network one extra layer (default is off).</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">HIDE SINGLETONS:</span> Hides nodes that have no incoming or outgoing edges (default is on)</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">HIDE LEAVES:</span> Hides nodes with only incoming edges (default is off)</div>";

  content +="<div style=\"color: steelblue; font-size:12px; font-weight: bold; margin: 8px 0px 4px 0px;\">LEGEND:</div>";

  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">EDGE COLOURS:</span> BLACK-- FANTOM4 Transcription factor binding site predictions and miRNA target predictions, YELLOW-- published protein-DNA edges, PURPLE-- protein-protein interactions, GREEN-- chip-chip(protein-DNA) edges, RED-- siRNA and miRNA perturbation edges.</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">EDGE LINE STYLE:</span> SOLID-- Direct edges, DASHED-- perturbation edges (possibly direct or indirect)</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">EDGE TERMINATORS:</span> Arrowhead-- activating relationships, Blunt-- repressing relationships, Round-- bidirectional protein-protein relationships</div>";
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">NODE SHAPE:</span> Round nodes are genes, hexagonal nodes are miRNAs.</div>"; 
  content +="<div style='margin-bottom: 1px;'><span style=\"font-weight: bold;\">NODE DIAMETER:</span> The diameter of each node is scaled to indicate the 'dynamics' of the gene. Calculated by mapping to log(max(detected ILMN expression)/min(detected ILMN expression)) within the time course.  Highly dynamic nodes are larger than statically expressed nodes.</div>";
  content +="<div><span style=\"font-weight: bold;\">NODE COLOUR:</span> The color of the node is mapped to a relative scale for each node between white for min(detected ILMN expression) and purple max(detected ILMN expression). If the node has no detectable ILMN expression, the name of the node becomes red and the background is white.</div>";

  infoToolTip(content, 800);
}


function centerview_input_output_info() {
  var content = "<div style=\"font-color: red; color: red; font-size:12px; font-weight: bold;\">Center view:  Input -> Node -> Output</div>";

  content += "<div style='margin: 8px 0px 4px 0px;'><span style=\"font-weight: bold;\">INPUT:</span> These are either known or predicted <span style=\"color:blue; font-weight:bold;\">regulators</span> of your gene's expression (eg. TF and microRNA).</div>";
  content += "<div style='margin: 8px 0px 4px 0px;'><span style=\"font-weight: bold;\">NODE:</span> This is the gene (coding, non-coding, or miRNA) you have selected. INPUT are TFs and microRNAs that regulate it, and OUTPUTS are downstream targets of your gene (if it is a TF or microRNA)</div>";
  content += "<div style='margin: 8px 0px 4px 0px;'><span style=\"font-weight: bold;\">OUTPUT:</span> These are either known or predicted <span style=\"color:blue; font-weight:bold;\">targets</span> of a transcription factor or microRNA.</div>";

  infoToolTip(content, 400);
}

